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
	
	var stopLoop = false

#if	os(Linux)
	let socketfd = socket( AF_INET, Int32(SOCK_STREAM.rawValue), 0 )
#else
	let socketfd = socket( AF_INET, SOCK_STREAM, 0 )
#endif
	

	func doRcv( on port: UInt16 ) {
		let bindResult = getConnector( on: port )
		if bindResult < 0 {
			printe( "\nFailed binding to port \(port)" )
			return
		}
		printx( "\nBound to local port \(port), start listening" )
		
		startThread(threadType: .inputThread )
		
		doListen()
	}
	
	
	func getConnector( on port: UInt16 ) -> Int32 {
		#if	os(Linux)
			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: htons(port), sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#else
			var serv_addr_in = sockaddr_in( sin_len: __uint8_t(MemoryLayout< sockaddr_in >.size), sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#endif

		let bindResult = withUnsafeMutablePointer(to: &serv_addr_in) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				bind(socketfd, $0, socklen_t(MemoryLayout.size(ofValue: serv_addr_in)))
			}
		}
		if bindResult < 0 {
			printe("\n\nERROR binding, errno: \(errno)")
		}
		return bindResult
	}
	
	
	func doListen() {

		initThreads()
		while !stopLoop {
			listen( socketfd, 5 )
			
			var cli_addr = sockaddr_in()
			var cli_len = socklen_t(MemoryLayout.size(ofValue: cli_addr))
			let cli_len_ptr = UnsafeMutablePointer<socklen_t>(withUnsafeMutablePointer(to: &cli_len, { $0 }))
			
			let newsockfd = withUnsafeMutablePointer( to: &cli_addr ) {
				$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
					accept( socketfd, $0, cli_len_ptr )	// Blocks waiting for connection
				}
			}
			if newsockfd < 0 {
				printe("\n\nERROR accepting, errno: \(errno)")
				stopLoop = true
			} else {
				let ipaddr = UInt32(cli_addr.sin_addr.s_addr)
				startThread( threadType: .serverThread, socket: newsockfd, address: ipaddr )
			}
		}
		freeThreads()
		exit( 0 )
	}
}
