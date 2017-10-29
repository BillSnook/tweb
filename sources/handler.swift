//
//  handler.swift
//  tweb
//
//  Created by William Snook on 9/30/17.
//
//

#if	os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

class Handler {
	
	public func processMsg( _ message: String ) -> Bool {

		let command = message.replacingOccurrences( of: "\n", with: "" )
		var endLoop = false
		switch command {
		case "superquit":
			endLoop = true	// Ends loop that sourced this command - network or console thread
		case "test":
#if	os(Linux)
			hardware.test()
#endif
		case "blink":
#if	os(Linux)
			hardware.blinkStart()
#endif
		case "blinkstop":
#if	os(Linux)
			hardware.stopLoop = false
#endif
		default:
			endLoop = false
		}

		return endLoop	// Default to false to have loop and thread continue
	}
}
