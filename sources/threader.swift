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
	case senderThread = "sender"
	case listenThread = "listen"
	case serverThread = "server"
	case inputThread = "input"
	case blinkThread = "blink"
	case testThread = "test"
}

struct ThreadControl {
	var nextThreadType: ThreadType
	var nextSocket: Int32
	var newAddress: UInt32
	init( threadType: ThreadType, socket: Int32 = 0, address: UInt32 = 0 ) {
		nextThreadType = threadType
		nextSocket = socket
		newAddress = address
	}
}

//	Globals
var threadArray = [ThreadControl]()				// List of threads to initiate
var threadControlMutex = pthread_mutex_t()		// Protect the list
var threadCount = 1								// Count main thread

var consumer: Consumer?

#if	os(Linux)
//let hardware = Hardware()
#endif


//--	----	----	----

// Manage thread environment because mutexes need this
func initThreads() {
	
	pthread_mutex_init( &threadControlMutex, nil )
}

func freeThreads() {
	
	pthread_mutex_destroy( &threadControlMutex )
}


// MARK: - Threads
class ThreadTester {
	
	// Test Thread
	func testThread() {
		
//        printx("  Thread ThreadTester.testThread() started\n")
//        printx("  Thread ThreadTester.testThread() stopped\n")
//        usleep( 2000000 )        // Let print text clear buffers, before exiting

        printx("  Thread getUPS()\n")
#if    os(Linux)
        hardware.getUPS()
#endif

    
    }
	
}


// MARK: - Server Thread
func serverThread( sockfd: Int32, address: UInt32 ) {
	
//	printx("  Thread serverThread started for socketfd \(sockfd)\n")
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
	var stopLoop = false
	
	var addrCString = [CChar]( repeating: 0, count: Int(INET_ADDRSTRLEN) )
	var inaddr = in_addr( s_addr: address )
	inet_ntop(AF_INET, &inaddr, &addrCString, UInt32(INET_ADDRSTRLEN))
	let addrString = String( cString: addrCString )
	printx( "\(sockfd)] Connection opened by \(addrString)" )
	
	while !stopLoop  {
		bzero( &readBuffer, 256 )
		let rcvLen = read( sockfd, &readBuffer, 255 )
		if (rcvLen < 0) {
			printe("\n\nERROR reading from newsocket")
			break
		}
		if rcvLen == 0 {
			printx( "\(sockfd)] Connection closed by \(addrString)" )
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
//	printx( "Thread count: \(threadCount) for \(nextThreadControl.nextThreadType.rawValue)" )

	switch nextThreadControl.nextThreadType {
	case .senderThread:
		sender?.doLoop()
	case .listenThread:
		listener?.doListen()
	case .serverThread:
		serverThread( sockfd: nextThreadControl.nextSocket, address: nextThreadControl.newAddress )
	case .inputThread:
		consumer = Consumer()
		consumer?.consume()
	case .blinkThread:
#if	os(Linux)
		hardware.blink()
#endif
	case .testThread:
		let testerThread = ThreadTester()
		testerThread.testThread()
	}
	threadCount -= 1
//	printx( "Threads remaining: \(threadCount) after exit for \(nextThreadControl.nextThreadType.rawValue)" )
}


// MARK: - Entry point - Start next thread in list
func startThread( threadType: ThreadType, socket: Int32 = 0, address: UInt32 = 0 ) {

	pthread_mutex_lock( &threadControlMutex )
	threadArray.append( ThreadControl( threadType: threadType, socket: socket, address: address ) )
	pthread_mutex_unlock( &threadControlMutex )
}

func createThread() {
	
	#if	os(Linux)
		let threadPtr = UnsafeMutablePointer<pthread_t>.allocate(capacity: 1)
	#else	// Darwin - MacOS    iOS?
		let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
	#endif
//	if threadPtr == nil {
//		printe( "\nUnable to create threadPointer for \(threadType.rawValue)\n" )
//		return
//	}
	defer { threadPtr.deallocate(capacity: 1) }
	var t = threadPtr.pointee
//	if t == nil {
//		printw( "\nUnable to see threadPointer pointee\n" )
////		return
//	}
	
	let attrPtr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
	defer { pthread_attr_destroy( attrPtr ) }
	pthread_attr_init( attrPtr )
	pthread_attr_setdetachstate( attrPtr, 0 )

	// No context can be captured in 3rd param because it is a C routine and knows not swift contexts
#if	os(Linux)
	pthread_create(&t,
	               attrPtr,
	               { _ in runThreads(); return nil },
	               nil)
#else	// Darwin - MacOS    iOS?
	pthread_create(&t,
				   attrPtr,
				   { _ in runThreads(); return nil },
				   nil)
#endif
}
