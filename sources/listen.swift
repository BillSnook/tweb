//
//  listen.swift
//  tweb
//
//  Created by William Snook on 9/28/17.
//

import Foundation
#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif


class Listen {
	
	var target: Host?
	var stopListening = false
	
#if	os(Linux)
	let socketfd = socket( AF_INET, Int32(SOCK_STREAM.rawValue), 0 )
#else
	let socketfd = socket( AF_INET, SOCK_STREAM, 0 )
#endif
	

	func doRcv( on port: UInt16 ) {
		let bindResult = getConnector( on: port )
		if bindResult < 0 {
			print( "\nFailed binding to port \(port)" )
			return
		}
		print( "\nBound to port \(port), start listening\n" )
		doListen()
		
//		close( newsocket )
	}
	
	
	func getConnector( on port: UInt16 ) -> Int32 {
		#if	os(Linux)
			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: htons(port), sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#else
			var serv_addr_in = sockaddr_in( sin_len: __uint8_t(MemoryLayout< sockaddr_in >.size), sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#endif

		print( "\n\nIn getConnection before calling bind\n" )
		let bindResult = withUnsafeMutablePointer(to: &serv_addr_in) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				bind(socketfd, $0, socklen_t(MemoryLayout.size(ofValue: serv_addr_in)))
			}
		}
		print( "\nIn getConnection with bindResult: \(bindResult)\n" )
		if bindResult < 0 {
			print("\n\nERROR binding, errno: \(errno)")
//			return bindResult
		}
		return bindResult
	}
	
	
	func doListen() {
		let notDone = true
		repeat {
			listen( socketfd, 5 )
			print( "  Got listen end-call, wait on accept\n" )
			var cli_addr = sockaddr_in()
			var cli_len = socklen_t(MemoryLayout.size(ofValue: cli_addr))
			let cli_len_ptr = UnsafeMutablePointer<socklen_t>(withUnsafeMutablePointer(to: &cli_len, { $0 }))
			
			let newsockfd = withUnsafeMutablePointer( to: &cli_addr ) {
				$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
					accept( socketfd, $0, cli_len_ptr )	// Blocks waiting for connection
				}
			}
			if newsockfd < 0 {
				print("\n\nERROR accepting, errno: \(errno)")
				exit(0)
			}
			print( "  Got accept end-call, create new thread\n" )
//			let tMgr = Threader( socketfd )
//			tMgr.createThread()
			let threadControl = ThreadControl( socket: newsockfd, threadType: .serverThread )
			threadArray.append( threadControl )
			startThread()

			usleep( 500000 )	// Delete when wait on thread start is done - it will protect newsockfd from overwrite
		} while notDone
		
	}
}
