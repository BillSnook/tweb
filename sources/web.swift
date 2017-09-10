//
//  web.swift
//  tweb
//
//  Created by William Snook on 9/7/17.
//
//

import Foundation
import SwiftyGPIO

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
 
        if gp17.value != 0 {
            sender.send( pin: "17", state: "on" )
        } else {
            sender.send( pin: "17", state: "off" )
        }
        if gp18.value != 0 {
            sender.send( pin: "18", state: "on" )
        } else {
            sender.send( pin: "18", state: "off" )
        }

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
/*
            let gp17Status = gp17.value != 0 ? " on" : "off"
            let gp18Status = gp18.value != 0 ? " on" : "off"
            print( "gp17 is \(gp17Status), gp18 is \(gp18Status)" )
*/
        }
    }
}



public class SendPinState {

    let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession( configuration: configuration )
    }
    
    deinit {
//        session
    }
    
    func send( pin: String, state: String ) {
        
        let urlString = "http://workpi.local:8080/" + state + pin
        send( urlString: urlString )
    }
    
    func send( urlString: String ) {
        let url = URL( string: urlString )
        print( "Sending \(urlString))" )
        
        let request = URLRequest(url: url!)
        //create dataTask using the session  to send data to the server
        let task = self.session.dataTask(with: request,
                            completionHandler: { data, response, error in
            guard error == nil else {
                print( "Error in response: \(String(describing: error))" )
                return
            }
            guard let data = data else {
                print( "No returned data" )
                return
            }
            let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print( dataString ?? "Send failed" )
            stayInProgram = false
        })
        
        task.resume()
    }


}

