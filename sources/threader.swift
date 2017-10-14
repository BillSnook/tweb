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


#if	os(Linux)

enum Signal:Int32 {
	case HUP    = 1
	case INT    = 2
	case QUIT   = 3
	case ABRT   = 6
	case KILL   = 9
	case ALRM   = 14
	case TERM   = 15
}

typealias SigactionHandler = @convention(c)(Int32) -> Void

let hupHandler:SigactionHandler = { signal in
	print( "Received HUP signal, reread config file" )
}

func trap( signum: Signal, action: SigactionHandler ) {
	var sigAction = sigaction()
	
	sigAction.__sigaction_handler = unsafeBitCast( action, to:  sigaction.__Unnamed_union___sigaction_handler.self )
	
	sigaction( signum.rawValue, &sigAction, nil )
}

// Entry, init function to setup trap handlers for common, expected signals
func setupSignalHandling() {
	
	// This method works
	trap( signum: .INT ) { signal in
		print("\nReceived INT signal, exiting now.\n")
		// Time for all threads to stop and cleanup, then exit
		exit(0)		// ? May not want to exit ?
	}
	
	// And this works of course
	trap( signum: .HUP, action: hupHandler )
}

#endif	// End of Linux-only section for signal handling


// Possible types of threads with which we work
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

//	Globals
var threadArray = [ThreadControl]()				// List of threads to initiate
var threadControlMutex = pthread_mutex_t()		// Protect the list

#if	os(Linux)
let hardware = Hardware()
#endif


//--	----	----	----

// MARK: - Threads
class ThreadTester {
	
	func testThread() {
		
		print("  Thread ThreadTester.testThread() started\n")
		print("  Thread ThreadTester.testThread() stopped\n")
		usleep( 2000000 )		// Let print text clear buffers, before exiting
	}
	
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
#if	os(Linux)
	nflags.c_lflag = tcflag_t(flags)
#else
#if Xcode
	nflags.c_lflag = UInt32(flags)
#else
	nflags.c_lflag = tcflag_t(flags)
#endif
#endif

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
	
	var addrCString = [CChar]( repeating: 0, count: Int(INET_ADDRSTRLEN) )
	var inaddr = in_addr( s_addr: address )
	inet_ntop(AF_INET, &inaddr, &addrCString, UInt32(INET_ADDRSTRLEN))
	let addrString = String( cString: addrCString )
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

	var tc: ThreadControl?
	pthread_mutex_lock( &threadControlMutex )
	if threadArray.count > 0 {
		tc = threadArray.remove(at: 0)
	}
	pthread_mutex_unlock( &threadControlMutex )
	guard let nextThreadControl = tc else { return }

	switch nextThreadControl.nextThreadType {
	case .serverThread:
		serverThread( sockfd: nextThreadControl.nextSocket, address: nextThreadControl.newAddress )
	case .inputThread:
		consumeThread()
	case .blinkThread:
#if	os(Linux)
		hardware.blink()
#endif
	case .testThread:
		let testerThread = ThreadTester()
		testerThread.testThread()
	}
}


// Manage thread environment because mutexes need this
func initThreads() {
	
	pthread_mutex_init( &threadControlMutex, nil )
}

func freeThreads() {
	
	pthread_mutex_destroy( &threadControlMutex )
}

// MARK: - Entry point - Start next thread in list
func startThread( threadType: ThreadType, socket: Int32, address: UInt32 ) {

	threadArray.append( ThreadControl( socket: socket, address: address, threadType: threadType ) )
	let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
	defer { threadPtr.deallocate(capacity: 1) }
	var t = threadPtr.pointee
	
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
	pthread_attr_destroy( attrPtr )
}
