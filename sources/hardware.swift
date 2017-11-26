//
//  hardware.swift
//  tweb
//
//  Created by William Snook on 10/7/17.
//

import Foundation

#if	os(Linux)
	
import Glibc
import SwiftyGPIO


enum ledState: int {
    case on     = 0
    case off    = 1
}

enum ledColor: int {
    case redLED     = 0
    case yellowLED  = 1
    case greenLED   = 2
}

class Hardware {
	
	var gpios: [GPIOName: GPIO]
	var red: GPIO
	var yellow: GPIO
	var green: GPIO

	var stopLoop = false
	
	init() {
		
		let numberOfProcessors = sysconf( Int32(_SC_NPROCESSORS_ONLN) )
//		printx("\nInit Hardware, number of cores: \(numberOfProcessors)\n")
		if numberOfProcessors == 1 {	// Must be ZeroW
			gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiPlusZero)
		} else {
			gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
		}
		
		red = gpios[.P18]!		// GPIO_GEN0
		yellow = gpios[.P17]!	// p18
		green = gpios[.P23]!	// p23
		
		red.direction = .OUT
		yellow.direction = .OUT
		green.direction = .OUT
		
		red.value = off
		yellow.value = off
		green.value = off
		
	}
	
	func blinkStart() {
		startThread( threadType: .blinkThread )
	}
	
	func delay() {
		_ = usleep(300000)
	}
	
	public func blink() {

		guard !stopLoop else { return }
		stopLoop = true
		repeat {
			red.value = on
			yellow.value = off
			green.value = off
			delay()
			red.value = off
			yellow.value = on
			green.value = off
			delay()
//			red.value = off
//			yellow.value = off
//			green.value = on
//			delay()
		} while stopLoop
		red.value = off
		yellow.value = off
		green.value = off
	}
	
	func test() {
		
		red.value = on
		delay()
		red.value = off
	}

    func colorLED( _ state: ledState, _ color: ledColor = .red ) {
        
        var color: GPIO
        switch ledColor {
        case .redLED:
            state = redGPIO
        case .yellowLED:
            state = yellowGPIO
        case .greenLED:
            state = greenGPIO
        default:
            state = redGPIO
        }
        color.value = state.rawValue
    }
    

}

/*
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

	
#else
	
//	import Darwin.C
	// We implicitly link to SwiftyGPIO in our project so we can compile in Xcode.
	// This should fail using the SPM in command line mode in MacOSX since we need to import there.
	
#endif
