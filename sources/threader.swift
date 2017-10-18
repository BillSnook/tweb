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


// Possible types of threads with which we work
enum ThreadType: String {
	case serverThread = "server"
	case inputThread = "input"
	case blinkThread = "blink"
	case testThread = "test"
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

//	Globals
var threadArray = [ThreadControl]()				// List of threads to initiate
var threadControlMutex = pthread_mutex_t()		// Protect the list
var threadCount = 1								// Count main thread

var consumer: Consumer?

#if	os(Linux)
let hardware = Hardware()
#endif


//--	----	----	----

// MARK: - Threads
class ThreadTester {
	
	// Test Thread
	func testThread() {
		
		printx("  Thread ThreadTester.testThread() started\n")
		printx("  Thread ThreadTester.testThread() stopped\n")
		usleep( 2000000 )		// Let print text clear buffers, before exiting
	}
	
}


// MARK: - Server Thread
func serverThread( sockfd: Int32, address: UInt32 ) {
	
//	printx("  Thread serverThread started for socketfd \(sockfd)\n")
	
	let messageHandler = Handler()
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
	var stopLoop = false
	
	var addrCString = [CChar]( repeating: 0, count: Int(INET_ADDRSTRLEN) )
	var inaddr = in_addr( s_addr: address )
	inet_ntop(AF_INET, &inaddr, &addrCString, UInt32(INET_ADDRSTRLEN))
	let addrString = String( cString: addrCString )
	printx( "\(sockfd)] Connection accepted from \(addrString)" )
	
	while !stopLoop  {
		bzero( &readBuffer, 256 )
		let rcvLen = read( sockfd, &readBuffer, 255 )
		if (rcvLen < 0) {
			printe("\n\nERROR reading from newsocket")
			break
		}
		if rcvLen == 0 {
			printx( "\(sockfd)] Connection closed by \(addrString), threads: \(threadCount - 1)" )
			break
		} else {	// rcvLen > 0
			guard let newdata = String( bytesNoCopy: &readBuffer, length: rcvLen, encoding: .utf8, freeWhenDone: false ) else {
				printw( "\nNo recognizable string data received, length: \(rcvLen)" )
				continue
			}
			printn( "\(sockfd)] \(newdata)" )	// Currently a newline is in the sent string
			
			let sndLen = write( sockfd, readBuffer, rcvLen)
			if (sndLen < 0) {
				printe("\n\nERROR writing to socket")
				continue
			}
			
			stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
		}
	}
//	printx( "  Exiting thread serverThread for socketfd \(sockfd)\n" )
	close( sockfd )
}

// MARK: - Thread controller
func runThreads() {

	var tc: ThreadControl?
	pthread_mutex_lock( &threadControlMutex )
	if threadArray.count > 0 {
		tc = threadArray.remove(at: 0)
	}
	pthread_mutex_unlock( &threadControlMutex )
	guard let nextThreadControl = tc else { return }
	
	threadCount += 1

	switch nextThreadControl.nextThreadType {
	case .serverThread:
		serverThread( sockfd: nextThreadControl.nextSocket, address: nextThreadControl.newAddress )
	case .inputThread:
		consumer = Consumer()
		consumer?.consume()
//		consumeThread()
	case .blinkThread:
#if	os(Linux)
		hardware.blink()
#endif
	case .testThread:
		let testerThread = ThreadTester()
		testerThread.testThread()
	}
	threadCount -= 1
}


// Manage thread environment because mutexes need this
func initThreads() {
	
	pthread_mutex_init( &threadControlMutex, nil )
}

func freeThreads() {
	
	pthread_mutex_destroy( &threadControlMutex )
}

// MARK: - Entry point - Start next thread in list
func startThread( threadType: ThreadType, socket: Int32 = 0, address: UInt32 = 0 ) {

	pthread_mutex_lock( &threadControlMutex )
	threadArray.append( ThreadControl( socket: socket, address: address, threadType: threadType ) )
	pthread_mutex_unlock( &threadControlMutex )

	let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
//	guard threadPtr != nil else {
//		printe( "\nUnable to create threadPointer for \(threadType.rawValue)\n" )
//		return
//	}
	defer { threadPtr.deallocate(capacity: 1) }
	var t = threadPtr.pointee
//	if t == nil {
//		printw( "\nUnable to see threadPointer pointee for \(threadType.rawValue)\n" )
////		return
//	}
	
	let attrPtr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
	defer { pthread_attr_destroy( attrPtr ) }
	pthread_attr_init( attrPtr )
	pthread_attr_setdetachstate( attrPtr, 0 )

	// No context can be captured in 3rd param because it is a C routine and knows not swift
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
//	pthread_attr_destroy( attrPtr )
}
