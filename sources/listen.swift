//
//  listen.swift
//  tweb
//
//  Created by William Snook on 9/28/17.
//

import Foundation

import Foundation
#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif


class Listen {
	
	var target: Host?
	
#if	os(Linux)
	let socketfd = socket( AF_INET, Int32(SOCK_STREAM.rawValue), 0 )
#else
	let socketfd = socket( AF_INET, SOCK_STREAM, 0 )
#endif
	

	func doRcv( on port: UInt16 ) {
		let newsocket = getConnector( on: port )
		if newsocket < 0 {
			print( "Failed accepting socket" )
			return
		}
		
		doWait( newSocket: newsocket )
		
		close( newsocket )
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
			return bindResult
		}
		print("\nListening on socket for port \(port)\n")
		listen( socketfd, 5 )
		
		var cli_addr = sockaddr_in()
		var cli_len = socklen_t(MemoryLayout.size(ofValue: cli_addr))
		let cli_addr_ptr = UnsafeMutablePointer<socklen_t>(withUnsafeMutablePointer(to: &cli_len, { $0 }))

		let newsockfd = withUnsafeMutablePointer( to: &cli_addr ) {
			$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
				accept( socketfd, $0, cli_addr_ptr )
			}
		}
		if newsockfd < 0 {
			print("\n\nERROR accepting, errno: \(errno)")
			return newsockfd
		}

		return newsockfd
	}
	
	
	func doWait( newSocket: Int32 ) {
		var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
		var sndLen: ssize_t = 0
		var rcvLen: ssize_t = 0
		while rcvLen < 255 {
			bzero( &readBuffer, 256 );
			rcvLen = read( newSocket, &readBuffer, 255 );
			if (rcvLen < 0) {
				print("\n\nERROR reading from newsocket")
			}

			if (rcvLen > 0) {
				if let newdata = String( bytesNoCopy: &readBuffer, length: rcvLen, encoding: .utf8, freeWhenDone: false ) {
					print( "\(newdata)" )
				} else {
					print( "No valid data received, length: \(rcvLen)" )
				}

				sndLen = write( newSocket, readBuffer, rcvLen);
				if (sndLen < 0) {
					print("\n\nERROR writing to socket");
				}
			}
		}
		
	}
}
