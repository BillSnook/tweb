//
//  main.swift
//
//
//  Created by William Snook on 8/28/17.
//
//

//#if os(Linux)
//import Glibc
//#else
//import Darwin.c
//#endif

import Foundation


var stayInProgram = true

// Defaults
var portNumber: UInt16 = 5555
var hostAddress = "workpi.local"    // "zerowpi2.local"

print( "There are \(CommandLine.arguments.count) command line arguments" )

if CommandLine.arguments.count == 1 {
	print( "USAGE: tweb [listen | sender] [portNumber] [hostName]" )
} else {
	if CommandLine.arguments[1] == "listen" {
		if CommandLine.arguments.count != 2 && CommandLine.arguments.count != 3 {
			print( "USAGE: tweb listen [portNumber(=\(portNumber))]" )
			exit(0)
		}
		if CommandLine.arguments.count > 2 {
			portNumber = UInt16(atoi( CommandLine.arguments[2] ))
		}
		let listener = Listen()
		listener.doRcv( on: portNumber )
	} else {
		if CommandLine.arguments.count > 2 {
			hostAddress = CommandLine.arguments[2] + ".local"
		}
		if CommandLine.arguments.count > 3 {
			portNumber = UInt16(atoi( CommandLine.arguments[3] ))
		}
		if CommandLine.arguments.count > 4 {
			print( "USAGE: tweb sender [hostName(=\(hostAddress)) [portNumber(=\(portNumber))]]" )
			exit(0)
		}
		let sender = Sender()
		sender.doSnd( to: hostAddress, at: portNumber )
	}
//	print( "" )
}
