//
//  hardware.swift
//  tweb
//
//  Created by William Snook on 10/7/17.
//

import Foundation

#if	os(Linux)
	
import Glibc
	
#else
	
import Darwin.C
	
#endif

//import SwiftyGPIO


let off = 0
let on  = 1


class Hardware {
	
	let gpios: [GPIOName: GPIO]
	let red: GPIO
	let yellow: GPIO
	let green: GPIO

	var state = 0
	
	init() {
		gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
		red = gpios[.P2]!		// p17
		yellow = gpios[.P3]!	// p18
		green = gpios[.P4]!	// p23
		
		red.direction = .OUT
		yellow.direction = .OUT
		green.direction = .OUT

		red.value = on
		yellow.value = on
		green.value = on
	}
	
}
