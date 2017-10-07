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

#else
	
import Darwin.C
// We implicitly link to SwiftyGPIO in our project so we can compile in Xcode.
// This should fail using the SPM in command line mode in MacOSX since we need to import there.
	
#endif



let off = 0
let on  = 1


class Hardware {
	
	let gpios: [GPIOName: GPIO]
	let red: GPIO
	let yellow: GPIO
	let green: GPIO

	var state = 0
	
	init() {
		
		let numberOfProcessors = sysconf( Int32(_SC_NPROCESSORS_ONLN) )
//		print("Number of processors: \(numberOfProcessors)")
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

		red.value = on
		yellow.value = on
		green.value = on
	}
	
	func blink() {

		func delay() {
			_ = usleep(400000)
		}
		
		repeat {
			red.value = 1
			yellow.value = 0
			green.value = 0
			delay()
			red.value = 0
			yellow.value = 1
			green.value = 0
			delay()
			red.value = 0
			yellow.value = 0
			green.value = 1
			delay()
		} while true
	}

}
