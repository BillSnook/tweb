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



let off = 0
let on  = 1


//class Hardware {
	
//	let red: GPIO?
//	let yellow: GPIO?
//	let green: GPIO?

	var stopLoop = true
	
	func blink() {
		
		var gpios: [GPIOName: GPIO]?
		let numberOfProcessors = sysconf( Int32(_SC_NPROCESSORS_ONLN) )
//		printx("\nInit Hardware, number of cores: \(numberOfProcessors)\n")
		if numberOfProcessors == 1 {	// Must be ZeroW
			gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiPlusZero)
		} else {
			gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
		}

		guard let red = gpios?[.P18]! else { return }		// GPIO_GEN0
		guard let yellow = gpios?[.P17]! else { return }	// p18
		guard let green = gpios?[.P23]! else { return }		// p23
		
		red.direction = .OUT
		yellow.direction = .OUT
		green.direction = .OUT

		red.value = off
		yellow.value = off
		green.value = off

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
		
//		red.value = on
//		delay()
//		red.value = off
	}
	
	func delay() {
		_ = usleep(300000)
	}
	
//}

#else
	
//	import Darwin.C
	// We implicitly link to SwiftyGPIO in our project so we can compile in Xcode.
	// This should fail using the SPM in command line mode in MacOSX since we need to import there.
	
#endif
