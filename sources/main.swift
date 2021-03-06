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

var mainLoop = true

var listener: Listen?
var sender: Sender?

// Mark - executable code starts here

#if	os(Linux)
setupSignalHandling()		    // Allow proper cleanup on unexpected exit signals (like ^C)
let hardware = Hardware()       // Support SwiftyGPIO library for Raspberry Pi pin functions support
#endif

let messageHandler = Handler()  //


//printx( "There are \(CommandLine.arguments.count) command line arguments" )

// Recomment verbose for testing (displays all others), error for just errors, warning for errors and warnings, none for none
level = .verbose
//printx always prints unless none

printx( "\ntweb socket communication program, v1.0\n\n" )

if CommandLine.arguments.count == 1 {	// Just the program name is entered
	printx( "USAGE: tweb [listen [portNumber (=\(portNumber))] | sender [hostName (=\(hostAddress))] [portNumber (=\(portNumber))]]" )
	exit(0)
} else {
//	printx( "Thread count: \(threadCount)  --  Main Thread running" )
	initThreads()
	if CommandLine.arguments[1] == "listen" {
		if CommandLine.arguments.count != 2 && CommandLine.arguments.count != 3 {
			printx( "USAGE: tweb listen [portNumber (=\(portNumber))]" )
			exit(0)
		}
		if CommandLine.arguments.count > 2 {
			portNumber = UInt16(atoi( CommandLine.arguments[2] ))
		}
		listener = Listen()
		mainLoop = listener!.doRcv( on: portNumber )
	} else if CommandLine.arguments[1] == "sender" {
		if CommandLine.arguments.count > 4 {
			printx( "USAGE: tweb sender [hostName (=\(hostAddress))]] [portNumber (=\(portNumber))]" )
			exit(0)
		}
		if CommandLine.arguments.count > 3 {
			portNumber = UInt16(atoi( CommandLine.arguments[3] ))
		}
		if CommandLine.arguments.count > 2 {
			hostAddress = CommandLine.arguments[2]
		}
		let localHostAddress = hostAddress + ".local"
		sender = Sender()
		mainLoop = sender!.doSnd( to: localHostAddress, at: portNumber )
	} else if CommandLine.arguments[1] == "tester" {
		printx( "\n  In Test Mode, starting test thread now\n" )
		startThread( threadType: .testThread )
	} else {
		printx( "USAGE: tweb [listen [portNumber (=\(portNumber))] | sender [hostName (=\(hostAddress))] [portNumber (=\(portNumber))]]" )
		mainLoop = false
	}
	
	var success = false
	while mainLoop {
		usleep( 10000 )
		pthread_mutex_lock( &threadControlMutex )
		success = threadArray.count > 0
		pthread_mutex_unlock( &threadControlMutex )
		if success {
			createThread()
		}
	}
	freeThreads()
//	printx( "Threads remaining: \(threadCount)  --  Main thread exiting" )
	pthread_exit( nil )
}
