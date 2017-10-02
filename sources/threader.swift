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


class Threader {
	
//	let numberOfCores: Int	// 4 for Pi3B, 1 for Pi0W
//
	let socketfd: Int32 = 0
	
	init( _ newsocketfd: Int32 ) {
		socketfd = newsocketfd
	}

	func runServerThread() -> Void {
		print("\nHello world!\n")
		var cli_addr = sockaddr_in()
		var cli_len = socklen_t(MemoryLayout.size(ofValue: cli_addr))
		let cli_len_ptr = UnsafeMutablePointer<socklen_t>(withUnsafeMutablePointer(to: &cli_len, { $0 }))
		
		let newsockfd = withUnsafeMutablePointer( to: &cli_addr ) {
			$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
				accept( socketfd, $0, cli_len_ptr )
			}
		}
		if newsockfd < 0 {
			print("\n\nERROR accepting, errno: \(errno)")
			exit(0)
		}
		
		let messageHandler = Handler()
		var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
		var stopLoop = false
		print("\nStart loop\n")
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
				print( "\(newdata)", terminator: "" )	// Currently a newline is included in the sent string
				
				let sndLen = write( newsockfd, readBuffer, rcvLen)
				if (sndLen < 0) {
					print("\n\nERROR writing to socket")
					continue
				}
				
				stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
			}
		}
		return ()
	}
	
	func getPthreadPtr() -> pthread_t? {
		
		let threadPtr = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
		return threadPtr.pointee
	}
	
	func createThread() {
		
		var t = getPthreadPtr()
		pthread_create( &t!, nil, { _ in
			runServerThread()
			return nil
		}, nil )
		
//		let ep = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
//		pthread_join(t!, ep)
		
	}

}
