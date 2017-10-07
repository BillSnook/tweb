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
		gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
		red = gpios[.P18]!		// p17
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
