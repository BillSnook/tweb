//
//  consumer.swift
//  tweb
//
//  Created by William Snook on 10/17/17.
//

#if	os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

class Consumer {
	
	var oflags = termios()
	var stopLoop = false

	func consume() {
		
		var readBuffer: [CChar] = [CChar](repeating: 0, count: 256)
		
		var nflags = termios()
		
		_ = tcgetattr( fileno(stdin), &oflags )
		nflags = oflags
		var flags = Int32(nflags.c_lflag)
		flags = flags & ~ECHO
		flags = flags & ~ECHONL
#if	os(Linux)
		nflags.c_lflag = tcflag_t(flags)
#else
#if Xcode
		nflags.c_lflag = UInt32(flags)
#else
		nflags.c_lflag = tcflag_t(flags)
#endif
#endif
		
		let result = tcsetattr( fileno(stdin), TCSADRAIN, &nflags )
		guard result == 0 else {
			printe("\n  Thread consumeThread failed setting tcsetattr with error: \(result)\n")
			return
		}
		
		printx( "\nBound to terminal with echo off, start waiting for input" )

		stopLoop = false
		while !stopLoop {
			bzero( &readBuffer, 256 )
			fgets( &readBuffer, 255, stdin )    // Blocks for input
			
			let len = strlen( &readBuffer )
			guard len > 0, let newdata = String( bytesNoCopy: &readBuffer, length: Int(len), encoding: .utf8, freeWhenDone: false ) else {
				printe( "\n  No recognizable string data received, length: \(len)" )
				continue
			}
			printn( "X] \(newdata)" )
			
			stopLoop = messageHandler.processMsg( newdata )	// Returns true if quit message is received
		}
		let result2 = tcsetattr( fileno(stdin), TCSANOW, &oflags )		// Restore input echo behavior
		guard result2 == 0 else {
			printe("\n  Thread consumeThread failed resetting tcsetattr with error: \(result2)\n")
			return
		}
	}
	
	func stopInput() {
		
		if !stopLoop {
			stopLoop = true
			let result = tcsetattr( fileno(stdin), TCSANOW, &oflags )		// Restore input echo behavior
			if result != 0 {
				printe("\n  Thread consumeThread failed resetting tcsetattr with error: \(result)\n")
			}
		}
		exit( 0 )
	}
}
