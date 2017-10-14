//
//  sender.swift
//  tweb
//
//  Created by William Snook on 9/20/17.
//

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


class Sender {

	var target: Host?
	#if	os(Linux)
	let socketfd = socket( AF_INET, Int32(SOCK_STREAM.rawValue), 0 )
	#else
	let socketfd = socket( AF_INET, SOCK_STREAM, 0 )
	#endif

	
	func lookup( name: String ) -> String? {
	
#if os(Linux)
		var hints = addrinfo(
			ai_flags: AI_PASSIVE,       // Assign the address of my local host to the socket structures
			ai_family: AF_INET,      	// IPv4
			ai_socktype: Int32(SOCK_STREAM.rawValue),   // TCP
			ai_protocol: 0, ai_addrlen: 0, ai_addr: nil, ai_canonname: nil, ai_next: nil )
#else
		var hints = addrinfo(
			ai_flags: AI_PASSIVE,       // Assign the address of my local host to the socket structures
			ai_family: AF_INET,      	// IPv4
			ai_socktype: SOCK_STREAM,   // TCP
			ai_protocol: 0, ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil )
#endif
		var servinfo: UnsafeMutablePointer<addrinfo>? = nil		// For the result from the getaddrinfo
		let status = getaddrinfo( name, "5555", &hints, &servinfo)
		guard status == 0 else {
			let stat = strerror( errno )
			print( "\ngetaddrinfo failed for \(name), status: \(status), error: \(String(cString: stat!))" )
			return nil
		}

		var targetAddr: String?
		var info = servinfo
		while info != nil {	// Get addresses
			var ipAddressString = [CChar]( repeating: 0, count: Int(INET_ADDRSTRLEN) )
			let sockAddrIn = info!.pointee.ai_addr.withMemoryRebound( to: sockaddr_in.self, capacity: 1 ) { $0 }
			var ipaddr_raw = sockAddrIn.pointee.sin_addr.s_addr
			inet_ntop( info!.pointee.ai_family, &ipaddr_raw, &ipAddressString, socklen_t(INET_ADDRSTRLEN))
			let ipaddrstr = String( cString: &ipAddressString )
			if strlen( ipaddrstr ) < 16 {
				targetAddr = ipaddrstr
				break		// Get first valid IPV4 address string
			}
			print( "\nGot target address: \(String(describing: target))" )
			info = info!.pointee.ai_next
		}
		freeaddrinfo( servinfo )
		return targetAddr
	}
	

	func doSnd( to: String, at: UInt16 ) {
	
		guard let targetAddr = lookup( name: to ) else {
//			print( "\nLookup failed for \(to)" )
			return
		}
//		print( "\nFound target address: \(targetAddr!)" )

		let result = doConnect( targetAddr, port: at )
		guard result >= 0 else {
			print( "\nConnect failed" )
			return
		}
		print( "\nConnecting on port \(at) to host \(to) (\(targetAddr))\n" )
		
		doLoop( socketfd )
		
		close( socketfd )
	}

	func doConnect( _ addr: String, port: UInt16 ) -> Int32 {
#if	os(Linux)
		var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: htons(port), sin_addr: in_addr( s_addr: inet_addr(addr) ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
#else
		var serv_addr_in = sockaddr_in( sin_len: __uint8_t(MemoryLayout< sockaddr_in >.size), sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: inet_addr(addr) ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
#endif
		let serv_addr_len = socklen_t(MemoryLayout.size( ofValue: serv_addr_in ))
		let connectResult = withUnsafeMutablePointer( to: &serv_addr_in ) {
			$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
				connect( socketfd, $0, serv_addr_len )
			}
		}
//		print( "\nIn getConnection with connectResult: \(connectResult)\n" )
		if connectResult < 0 {
			print("\nERROR connecting, errno: \(errno)")
		}
		
		return connectResult
	}
	
	
	func doLoop( _ socketfd: Int32 ) {
		var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
		var writeBuffer: [CChar] = [CChar](repeating: 0, count: 256)
		let stopLoop = false
		while !stopLoop {
			print( "> ", terminator: "" )
			bzero( &writeBuffer, 256 )
			fgets( &writeBuffer, 255, stdin )    // Blocks for input
			
			let len = strlen( &writeBuffer )
			let sndLen = write( socketfd, &writeBuffer, Int(len) )
			if ( sndLen < 0 ) {
				print( "\n\nERROR writing to socket" )
				break
			}

			bzero( &readBuffer, 256 )
			let rcvLen = read( socketfd, &readBuffer, 255 )
			if (rcvLen < 0) {
				print( "\n\nERROR reading from socket" )
				break
			}
		}
		
	}
}

