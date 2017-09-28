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

	
	func lookup( name: String ) -> Host? {
		
		target = Host( name: name )
		guard target != nil else {
			print( "Lookup failed for \(name)" )
			return nil
		}
		let addrs = target!.addresses
		guard addrs.count > 0 else {
			print( "Host call succeeded but no addresses were returned" )
			return nil
		}
		
		print( "Host call succeeds, count: \(addrs.count)" )
		for addr in addrs {
			print( "  addr: \(addr)" )
		}
		for name in target!.names { // We're not getting names when looking up Pi devices
			print( "  name: \(name)" )
		}

		return target
	}
	

	func doSnd( to: String, at: UInt16 ) {
	
		guard let server = lookup( name: to ) else {
			print( "Lookup failed for \(to)" )
			return
		}
		let addrs = server.addresses
		guard addrs.count > 0 else {
			print( "No addresses returned for \(to)" )
			return
		}

		print( "Address string: \(addrs.first!)" )
		let result = doConnect( addrs.first!, port: at )
		guard result >= 0 else {
			print( "Connect failed" )
			return
		}
		print( "Got socket on which to send\n" )

		doLoop()
		
		close( socketfd )
	}

	func doConnect( _ addr: String, port: UInt16 ) -> Int32 {
		#if	os(Linux)
			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: inet_addr(addr) ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#else
//			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: inet_addr(addr) ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
			var serv_addr_in = sockaddr_in( sin_len: __uint8_t(MemoryLayout< sockaddr_in >.size), sin_family: sa_family_t(AF_INET), sin_port: port.bigEndian, sin_addr: in_addr( s_addr: inet_addr(addr) ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#endif
		let serv_addr_len = socklen_t(MemoryLayout.size( ofValue: serv_addr_in ))
		print( "in getConnection before calling connect\n" )
		let connectResult = withUnsafeMutablePointer( to: &serv_addr_in ) {
			$0.withMemoryRebound( to: sockaddr.self, capacity: 1 ) {
				connect( socketfd, $0, serv_addr_len )
			}
		}
		print( "\nIn getConnection with connectResult: \(connectResult)\n" )
		if connectResult < 0 {
			print("ERROR connecting, errno: \(errno)")
		}
		
		return connectResult
	}
	
	
	func doLoop() {
		var buffer: [CChar] = [CChar](repeating: 0, count: 256)
		var n: ssize_t = 0
		//		print( "Enter doLoop" );
		while n < 255 {
			
			// TODO: check inputs here to see if message is to be set else prompt
			print( "> ", terminator: "" );
			bzero( &buffer, 256 );
			fgets( &buffer, 255, stdin );    // Blocks for input
			
			let len = strlen( &buffer )
			n = write( socketfd, &buffer, Int(len) );
			if (n < 0) {
				print("\n\nERROR writing to socket")
			}
			
			bzero( &buffer, 256 );
			n = read( socketfd, &buffer, 255 );
			if (n < 0) {
				print("\n\nERROR reading from socket")
			}
			
			print("\(n) bytes received: \(buffer)");
		}
		
	}
}

