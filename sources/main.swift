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

var portNumber: UInt16 = 5555
var hostAddress = "workpi.local"    // "zerowpi2.local"

print( "There are \(CommandLine.arguments.count) command line arguments" )

if CommandLine.arguments.count == 0 {
	print( "USAGE: tweb [listen | sender] [portNumber] [hostName]" )
} else {
	if CommandLine.arguments.count > 1 {
		portNumber = UInt16(atoi( CommandLine.arguments[1] ))
	}
	
	if CommandLine.arguments.count > 2 {
		hostAddress = CommandLine.arguments[2]
	}
	
	print( "" )
	if CommandLine.arguments[2] == "listen" {
		print( "listen mode is not yet implemented" )
	} else {
		let sender = Snd()
		sender.doSnd( to: hostAddress, at: portNumber )
	}
}
