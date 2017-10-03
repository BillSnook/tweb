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


var nextIncomingSocket: Int32 = 0


func runServerThread() {

	let newsockfd = nextIncomingSocket
	print("  Server thread runServerThread started for socketfd \(newsockfd)\n")

	let messageHandler = Handler()
	var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
	var stopLoop = false
	while !stopLoop  {
		bzero( &readBuffer, 256 )
		let rcvLen = read( newsockfd, &readBuffer, 255 )
		if (rcvLen < 0) {
			print("\n\nERROR reading from newsocket")
			continue
		}
		if rcvLen == 0 {
			print("\n\nDisconnected from the other endpoint. Exiting thread now.")
			exit(0)
		} else {	// rcvLen > 0
			guard let newdata = String( bytesNoCopy: &readBuffer, length: rcvLen, encoding: .utf8, freeWhenDone: false ) else {
				print( "No recognizable string data received, length: \(rcvLen)" )
				continue
			}
			print( "] \(newdata)", terminator: "" )	// Currently a newline is included in the sent string
			
			let sndLen = write( newsockfd, readBuffer, rcvLen)
			if (sndLen < 0) {
				print("\n\nERROR writing to socket")
				continue
			}
			
			stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
		}
	}
	print( "  Exiting thread runServerThread for socketfd \(newsockfd)\n" )
}

func getPthread() -> pthread_t? {
	let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
	return threadPtr.pointee
}

func createThread( _ newsockfd: Int32 ) {
	
	var t = getPthread()
	nextIncomingSocket = newsockfd
#if	os(Linux)
	pthread_create(&t!,
	               nil,
	               { _ in runServerThread(); return nil },
	               nil)
#else
	pthread_create(&t,
				   nil,
				   { _ in runServerThread(); return nil },
				   nil)
#endif
}





//class Threader {
//
////	let numberOfCores: Int	// 4 for Pi3B, 1 for Pi0W
////
//	let socketfd: Int32 = 0
//
//	init( _ newsocketfd: Int32 ) {
//		socketfd = newsocketfd
//	}
//
//
//	func getPthreadPtr() -> pthread_t? {
//
//		let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
//		return threadPtr.pointee
//	}
//
//	func createThread() {
//
//		var t = getPthreadPtr()
//		pthread_create( &t!, nil, { (x:UnsafeMutableRawPointer) in
//			print( "Thread: \(x.description)" )
////			runServerThread()
//			sayHello2()
//			return nil
//		}, nil )
//
////		let ep = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
////		pthread_join(t!, ep)
//
//	}
//
//}

