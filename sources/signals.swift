//
//  signals.swift
//  tweb
//
//  Created by William Snook on 10/15/17.
//

#if	os(Linux)
import Glibc
	
enum Signal:Int32 {
	case HUP    = 1
	case INT    = 2		// ^C
	case QUIT   = 3
	case ABRT   = 6
	case KILL   = 9
	case ALRM   = 14
	case TERM   = 15
}

typealias SigactionHandler = @convention(c)(Int32) -> Void

let hupHandler:SigactionHandler = { signal in
	print( "\nReceived HUP signal, reread config file\n" )
}

func trap( signum: Signal, action: SigactionHandler ) {
	var sigAction = sigaction()
	
	sigAction.__sigaction_handler = unsafeBitCast( action, to:  sigaction.__Unnamed_union___sigaction_handler.self )
	
	sigaction( signum.rawValue, &sigAction, nil )
}

// Entry, init function to setup trap handlers for common, expected signals
func setupSignalHandling() {
	
	// This method works with block
	trap( signum: .INT ) { signal in
		print("\nReceived INT signal, exiting now.\n")
		// Time for all threads to stop and cleanup, then exit
		// Each thread that does not end quickly needs a method to halt itself so we can exit cleanly
		consumer?.stopInput()
		sender?.stopLoop = true
		listener?.stopLoop = true
		mainLoop = false
		
		exit(0)		// ? May not want to exit just yet ?
	}
	
	// And this works of course, with handler
	trap( signum: .HUP, action: hupHandler )
}
	
#endif	// End of Linux-only section for signal handling


enum Level: String {
	case none
	case error
	case warning
	case verbose
	case user1
	case user2
	case user3
	case user4
}

var level = Level.none

func printx( _ message: String ) {				// Print always (unless none) - effectively verbose
	if level != .none {
		print( message )
	}
}

//func printv( _ message: String ) {			// Print only if verbose
//	if level == .verbose {
//		print( message )
//	}
//}

func printe( _ message: String ) {
	if level == .verbose || level == .error {	// Print error
		print( message )
	}
}

func printw( _ message: String ) {
	if level == .verbose || level == .error || level == .warning {	// Print error and warning
		print( message )
	}
}

func printu1( _ message: String ) {
	if level == .verbose || level == .error || level == .user1 {
		print( message )
	}
}

func printu2( _ message: String ) {
	if level == .verbose || level == .error || level == .user2 {
		print( message )
	}
}

func printu3( _ message: String ) {
	if level == .verbose || level == .error || level == .user3 {
		print( message )
	}
}

func printu4( _ message: String ) {
	if level == .verbose || level == .error || level == .user4 {
		print( message )
	}
}

func printn( _ message: String ) {				// Print without implicit newline terminator
	if level != .none {
		print( message, terminator: "" )
	}
}



