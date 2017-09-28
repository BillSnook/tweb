//
//  snd.swift
//  tweb
//
//  Created by William Snook on 9/20/17.
//

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif


// Get socket to send on
// Get target reference - hostname.local to ip addr - bonjour |? dns
// Server address from target ref stuff, set port number
// Connect
// Repeat
//   write
//   read - blocks for data, assumed to be a response
// EndRepeat?
// Close socket

class Snd {

	var target: Host?

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
		let cm = ConnectManager()
		cm.doConnect( addrs.first!, port: at )
	}
}

