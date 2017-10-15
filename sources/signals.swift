//
//  signals.swift
//  tweb
//
//  Created by William Snook on 10/15/17.
//

#if	os(Linux)
import Glibc
#else
import Darwin.C
#endif


#if	os(Linux)
	
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
	
	// This method works
	trap( signum: .INT ) { signal in
		print("\nReceived INT signal, exiting now.\n")
		// Time for all threads to stop and cleanup, then exit
		// Each thread that does not end quickly needs a method to halt itself so we can exit cleanly
//		Sender.stopLoop = true
//		Listen.stopLoop = true
		
		exit(0)		// ? May not want to exit ?
	}
	
	// And this works of course
	trap( signum: .HUP, action: hupHandler )
}
	
#endif	// End of Linux-only section for signal handling
