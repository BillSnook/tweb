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

//		let command = message.replacingOccurrences( of: "\n", with: "" )
//		print( "\n  Got command: <\(command)>\n" )
		var endLoop = false
		switch message {
		case "quit\n":
			endLoop = true
		case "test\n":
#if	os(Linux)
			hardware.test()
#endif
		case "blink\n":
			threadArray.append( ThreadControl( socket: 0, address: 0, threadType: .blinkThread ) )
			startThread()
		case "blinkstop\n":
#if	os(Linux)
			hardware.blinkLoop = false
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
            print( "Pin 17 is on" )
            sender.send( pin: "17", state: "on" )
       }
        gp17.onFalling {
            gpio in
            print( "Pin 17 is off" )
            sender.send( pin: "17", state: "off" )
        }
        gp18.onRaising {
            gpio in
            print( "Pin 18 is on" )
            sender.send( pin: "18", state: "on" )
        }
        gp18.onFalling {
            gpio in
            print( "Pin 18 is off" )
            sender.send( pin: "18", state: "off" )
        }

        while true {
            usleep(100000)
        }
    }
}
*/
