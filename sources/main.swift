//
//  main.swift
//
//
//  Created by William Snook on 8/28/17.
//
//

import Foundation


// Defaults
var portNumber: UInt16 = 5555
var hostAddress = "zerowpi2"    // or "workpi"


// Mark - executable code starts here

#if	os(Linux)
setupSignalHandling()		// Allow proper cleanup on unexpected exit signals (like ^C)
#endif

//print( "There are \(CommandLine.arguments.count) command line arguments" )

if CommandLine.arguments.count == 1 {	// Just the program name is entered
	print( "USAGE: tweb [listen [portNumber (=\(portNumber))] | sender [hostName (=\(hostAddress))] [portNumber (=\(portNumber))]]" )
	exit(0)
} else {
	if CommandLine.arguments[1] == "listen" {
		if CommandLine.arguments.count != 2 && CommandLine.arguments.count != 3 {
			print( "USAGE: tweb listen [portNumber (=\(portNumber))]" )
			exit(0)
		}
		if CommandLine.arguments.count > 2 {
			portNumber = UInt16(atoi( CommandLine.arguments[2] ))
		}
		let listener = Listen()
		listener.doRcv( on: portNumber )
	} else if CommandLine.arguments[1] == "sender" {
		if CommandLine.arguments.count > 4 {
			print( "USAGE: tweb sender [hostName (=\(hostAddress))]] [portNumber (=\(portNumber))]" )
			exit(0)
		}
		if CommandLine.arguments.count > 3 {
			portNumber = UInt16(atoi( CommandLine.arguments[3] ))
		}
		if CommandLine.arguments.count > 2 {
			hostAddress = CommandLine.arguments[2]
		}
		let localHostAddress = hostAddress + ".local"
		let sender = Sender()
		sender.doSnd( to: localHostAddress, at: portNumber )
	} else if CommandLine.arguments[1] == "tester" {
		print( "\n  In Test Mode, starting test now\n" )
		startThread( threadType: .testThread, socket: 0, address: 0 )
	}
}
