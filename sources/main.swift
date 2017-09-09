//
//  main.swift
//
//
//  Created by William Snook on 8/28/17.
//
//

//#if os(Linux)
//import Glibc
//#else
//import Darwin.c
//#endif

import Foundation
//import SwiftyGPIO

var stayInProgram = true

//let sender = SendPinState()
//sender.send( "2", "on" )

let watcher = WatchPins()
watcher.trackPins()


while stayInProgram {
    usleep(100000)
}

