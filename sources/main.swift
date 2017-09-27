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

let CONNECTION_PORT = 5555
let CONNECTION_HOST = "zerowpi2.local"
//let CONNECTION_HOST = "workpi.local"

var stayInProgram = true

func main(argc: Int, argv: )
let sender = Snd()
sender.doSnd( to: CONNECTION_HOST )


//let watcher = WatchPins()
//watcher.trackPins()
//while stayInProgram {
//    usleep(100000)
//}

