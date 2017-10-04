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
}

struct ThreadControl {
	var nextSocket: Int32
	var nextThreadType: ThreadType
	init( socket: Int32, threadType: ThreadType ) {
		nextSocket = socket
		nextThreadType = threadType
	}
}

var threadArray = [ThreadControl]()


// MARK: - Threads
func testThread() {
	
	print("  Test thread testThread started\n")
}

func serverThread( sockfd: Int32 ) {
	
	print("  Server thread serverThread started for socketfd \(sockfd)\n")
	
	let messageHandler = Handler()
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
	var stopLoop = false
	while !stopLoop  {
		bzero( &readBuffer, 256 )
		let rcvLen = read( sockfd, &readBuffer, 255 )
		if (rcvLen < 0) {
			print("\n\nERROR reading from newsocket")
			continue
		}
		if rcvLen == 0 {
			print("\n  Disconnected from the other endpoint. Exiting thread now.")
			break
		} else {	// rcvLen > 0
			guard let newdata = String( bytesNoCopy: &readBuffer, length: rcvLen, encoding: .utf8, freeWhenDone: false ) else {
				print( "No recognizable string data received, length: \(rcvLen)" )
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
	print( "  Exiting thread serverThread for socketfd \(sockfd)\n" )
	close( sockfd )
}

// MARK: - Thread controller
func runThreads() {

	guard threadArray.count > 0 else { return }
	
	let nextThreadControl = threadArray.remove(at: 0)
	switch nextThreadControl.nextThreadType {
	case .serverThread:
		serverThread( sockfd: nextThreadControl.nextSocket )
	case .inputThread:
		testThread()
	}

}

func getPthread() -> pthread_t? {
	let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
	return threadPtr.pointee
}

// MARK: - Entry point - Start next thread in list
func startThread() {
	
	var t = getPthread()			// Memory leak, needs solution
#if	os(Linux)
	pthread_create(&t!,
	               nil,
	               { _ in runThreads(); return nil },
	               nil)
#else	// Darwin - MacOS    iOS?
	pthread_create(&t,
				   nil,
				   { _ in runThreads(); return nil },
				   nil)
#endif
}
