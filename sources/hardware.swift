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


let on     = 0
let off    = 1

enum ledState: Int {
    case offLED  = 0
    case onLED = 1
}

enum ledColor {
    case redLED
    case yellowLED
    case greenLED
}
    
class Hardware {
	
	var gpios: [GPIOName: GPIO]
	var red: GPIO
	var yellow: GPIO
	var green: GPIO

	var stopLoop = true
	
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
		
		clearLEDs()
	}
	
    func delay() {
        _ = usleep(300000)
    }
    
	func blinkStart() {
        guard stopLoop else { return }          // Verify blink is not already started
		startThread( threadType: .blinkThread )
	}
	
    public func blinkStop() {
        if stopLoop {
            clearLEDs()
        } else {
            stopLoop = true     // LEDs clear on loop stoppage
        }
    }
    
    public func blink() {

        stopLoop = false
		while !stopLoop {
			red.value = ledState.onLED.rawValue
			yellow.value = ledState.offLED.rawValue
			green.value = ledState.offLED.rawValue
			delay()
			red.value = ledState.offLED.rawValue
			yellow.value = ledState.onLED.rawValue
			green.value = ledState.offLED.rawValue
			delay()
//			red.value = ledState.offLED.rawValue
//			yellow.value = ledState.offLED.rawValue
//			green.value = ledState.onLED.rawValue
//			delay()
		}
        clearLEDs()
	}
	
	func test() {
		
		red.value = ledState.onLED.rawValue
		delay()
		red.value = ledState.offLED.rawValue
    }
    
    func clearLEDs() {
        red.value = ledState.offLED.rawValue
        yellow.value = ledState.offLED.rawValue
        green.value = ledState.offLED.rawValue
    }
    
    func colorLED( _ state: ledState, _ colorOfLED: ledColor ) {

        var pin: GPIO
        switch colorOfLED {
        case .redLED:
            pin = self.red
        case .yellowLED:
            pin = self.yellow
        case .greenLED:
            pin = self.green
       }
        pin.value = state.rawValue
    }

    func getUPS() {
        
        let vreg: UInt8 = 2
        let creg: UInt8 = 4
        let adrs: Int = 0x36
        
        let i2cs = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPi2)!
        let i2c = i2cs[1]
        
        print("Detecting devices on the I2C bus:\n")
        outer: for i in 0x0...0x7 {
            if i == 0 {
                print("    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f")
            }
            for j in 0x0...0xf {
                if j == 0 {
                    print(String(format:"%x0",i), terminator: "")
                }
                // Test within allowed range 0x3...0x77
                if (i==0) && (j<3) {print("   ", terminator: "");continue}
                if (i>=7) && (j>=7) {break outer}
                
                print(" \(i2c.isReachable(i<<4 + j) ? " x" : " ." )", terminator: "")
            }
            print()
        }
        print("\n")
        
        // Reading register 0 of the device with address 0x68
        //print(i2c.readByte(0x68, command: 0))
        
        // Reading register 1 of the device with address 0x68
        //print(i2c.readByte(0x68, command: 1))
        
        // Writing register 0 of the device with address 0x68
        //i2c.writeByte(0x68, command: 0, value: 0)
        
        // Reading again register 0 of the device with address 0x68
        //print(i2c.readByte(0x68, command: 0))

        let v1: UInt16 = i2c.readWord( adrs, command: vreg )
        print("v1: \(v1) - \( (Float(v1) * 78.125) / 1000000.0 )V straight");
        swapBytes( v1 )
        print("v2: \(v1) - \( (Float(v1) * 78.125) / 1000000.0 )V switched");


    }
    
    func swapBytes( _ word: inout UInt16 ) {
        
        let lo = ( word >> 8 ) & 0xFF
        let hi = ( word & 0xFF ) << 8
        print( "hi: \(hi), lo: \(lo)" )
        word = hi | lo
        print( "word: \(word)")
    }
}


/*
void Motor::getUPS() {
    
    int vOpt = 1, cOpt = 1;
    unsigned char buf[BUFSIZE] = {0};
    
    int busfd;
    if ((busfd = open(DEV, O_RDWR)) < 0) {
        printf("can't open %s (running as root?)\n",DEV);
        return;
    }
    
    int ret = ioctl(busfd, I2C_SLAVE, ADRS);
    if (ret < 0) {
        printf("i2c device initialisation failed\n");
        return;
    }
    
    readReg(busfd, VREG, buf, 2);
    
    int hi,lo;
    hi = buf[0];
    lo = buf[1];
    int v = (hi << 8)+lo;
    if (vOpt) {
        fprintf( stderr, "%fV ",(((float)v)* 78.125 / 1000000.0));
    }
    
    readReg(busfd, CREG, buf, 2);
    hi = buf[0];
    lo = buf[1];
    v = (hi << 8)+lo;
    if (!cOpt && !vOpt) {
        fprintf( stderr, "%i",(int)(((float)v) / 256.0));
    }
    
    if (cOpt) {
        fprintf( stderr, "%f%%",(((float)v) / 256.0));
    }
    
    fprintf( stderr, "\n");
    
    close(busfd);
}
*/

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
