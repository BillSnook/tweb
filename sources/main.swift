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

let watcher = WatchPins()
watcher.trackPins()


while stayInProgram {
    usleep(100000)
}

