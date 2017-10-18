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
			endLoop = true
		case "test":
#if	os(Linux)
//			hardware.test()
			test()
#endif
		case "blink":
			startThread( threadType: .blinkThread )
		case "blinkstop":
#if	os(Linux)
			stopLoop = false
//			hardware.stopLoop = false
#endif
		default:
			endLoop = false
		}

		return endLoop	// Default to false to have loop and thread continue
	}
}



/*
import Foundation

public class WatchPins {
    
    let gpios: [GPIOName: GPIO]
    let gp17: GPIO
    let gp18: GPIO
    
    init() {
        gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
        gp17 = gpios[.P17]!
        gp18 = gpios[.P18]!
    }
    
    func trackPins() {

        let sender = SendPinState()
        sender.send( urlString: "http://workpi.local:8080/startup" )

        gp17.direction = .IN
        gp18.direction = .IN
 
         gp17.onRaising {
            gpio in
            printx( "Pin 17 is on" )
            sender.send( pin: "17", state: "on" )
       }
        gp17.onFalling {
            gpio in
            printx( "Pin 17 is off" )
            sender.send( pin: "17", state: "off" )
        }
        gp18.onRaising {
            gpio in
            printx( "Pin 18 is on" )
            sender.send( pin: "18", state: "on" )
        }
        gp18.onFalling {
            gpio in
            printx( "Pin 18 is off" )
            sender.send( pin: "18", state: "off" )
        }

        while true {
            usleep(100000)
        }
    }
}
*/
