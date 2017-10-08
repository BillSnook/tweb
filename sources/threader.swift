//
//  threader.swift
//  tweb
//
//  Created by William Snook on 10/1/17.
//

#if	os(Linux)

import Glibc

#else

import Darwin.C

#endif


enum ThreadType {
	case serverThread
	case inputThread
	case blinkThread
	case testThread
}

struct ThreadControl {
	var nextSocket: Int32
	var newAddress: UInt32
	var nextThreadType: ThreadType
	init( socket: Int32, address: UInt32, threadType: ThreadType ) {
		nextSocket = socket
		newAddress = address
		nextThreadType = threadType
	}
}

var threadArray = [ThreadControl]()

let hardware = Hardware()


// MARK: - Threads
func testThread() {
	
	print("  Thread testThread started and stopped\n")
}

func blinkThread() {

	func delay() {
		_ = usleep(400000)
	}
	
	print("  Thread blinkThread started\n")
	
	hardware.blink()

	print("  Thread blinkThread stopped\n")
}

func consumeThread() {
	
//	print("  Thread consumeThread started\n")
	
	let messageHandler = Handler()
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)

	var oflags = termios()
	var nflags = termios()
	
	_ = tcgetattr( fileno(stdin), &oflags )
	nflags = oflags
	var flags = Int32(nflags.c_lflag)
	flags = flags & ~ECHO
	flags = flags & ~ECHONL
	nflags.c_lflag = UInt32(flags)

	let result = tcsetattr( fileno(stdin), TCSADRAIN, &nflags )
	guard result == 0 else {
		print("\n  Thread consumeThread failed setting tcsetattr with error: \(result)\n")
		return
	}

	var stopLoop = false
	while !stopLoop {
		bzero( &readBuffer, 256 )
		fgets( &readBuffer, 255, stdin )    // Blocks for input

		let len = strlen( &readBuffer )
		guard let newdata = String( bytesNoCopy: &readBuffer, length: Int(len), encoding: .utf8, freeWhenDone: false ) else {
			print( "\n  No recognizable string data received, length: \(len)" )
			continue
		}
//		print( newdata, terminator: "" )
		
		stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
	}
	_ = tcsetattr( fileno(stdin), TCSANOW, &oflags )		// Restore input echo behavior
	guard result == 0 else {
		print("\n  Thread consumeThread failed resetting tcsetattr with error: \(result)\n")
		return
	}

	print("  Thread consumeThread stopped\n")
}

func serverThread( sockfd: Int32, address: UInt32 ) {
	
//	print("  Thread serverThread started for socketfd \(sockfd)\n")
	
	let messageHandler = Handler()
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
	var stopLoop = false
	
	let addrCString = UnsafeMutablePointer<Int8>.allocate(capacity: 16)
	var inaddr = in_addr( s_addr: address )
	inet_ntop(AF_INET, &inaddr, addrCString, 16)
	let addrString = String( cString: addrCString )
	addrCString.deinitialize()
	addrCString.deallocate(capacity: 16)
	print( "\(sockfd)] Connection accepted from \(addrString)" )
	
	while !stopLoop  {
		bzero( &readBuffer, 256 )
		let rcvLen = read( sockfd, &readBuffer, 255 )
		if (rcvLen < 0) {
			print("\n\nERROR reading from newsocket")
			continue
		}
		if rcvLen == 0 {
//			print("\n  Disconnected from the other endpoint. Exiting thread now.")
			print( "\(sockfd)] Connection closed by \(addrString)" )
			break
		} else {	// rcvLen > 0
			guard let newdata = String( bytesNoCopy: &readBuffer, length: rcvLen, encoding: .utf8, freeWhenDone: false ) else {
				print( "\nNo recognizable string data received, length: \(rcvLen)" )
				continue
			}
			print( "\(sockfd)] \(newdata)", terminator: "" )	// Currently a newline is already included in the sent string
			
			let sndLen = write( sockfd, readBuffer, rcvLen)
			if (sndLen < 0) {
				print("\n\nERROR writing to socket")
				continue
			}
			
			stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
		}
	}
//	print( "  Exiting thread serverThread for socketfd \(sockfd)\n" )
	close( sockfd )
}

// MARK: - Thread controller
func runThreads() {

	guard threadArray.count > 0 else { return }
	
	let nextThreadControl = threadArray.remove(at: 0)
	switch nextThreadControl.nextThreadType {
	case .serverThread:
		serverThread( sockfd: nextThreadControl.nextSocket, address: nextThreadControl.newAddress )
	case .inputThread:
		consumeThread()
	case .blinkThread:
		blinkThread()
	case .testThread:
		testThread()
	}

}


// MARK: - Entry point - Start next thread in list
func startThread() {
	
	let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
	defer { threadPtr.deallocate(capacity: 1) }
	var t = threadPtr.pointee
	
	let attrPtr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
	defer { pthread_attr_destroy( attrPtr ) }
	pthread_attr_init( attrPtr )
	pthread_attr_setdetachstate( attrPtr, 0 )

#if	os(Linux)
	pthread_create(&t!,
	               attrPtr,
	               { _ in runThreads(); return nil },
	               nil)
#else	// Darwin - MacOS    iOS?
	pthread_create(&t,
				   attrPtr,
				   { _ in runThreads(); return nil },
				   nil)
#endif
	pthread_attr_destroy( attrPtr )
}
