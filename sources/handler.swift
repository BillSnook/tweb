//
//  handler.swift
//  tweb
//
//  Created by William Snook on 9/30/17.
//
//

#if	os(Linux)
import Glibc
#else
import Darwin
#endif

class Handler {
	
	public func processMsg( _ message: String ) -> Bool {
		
		if message == "quit\n" {
			return true
		}
//		print( "Got message: \(message)" )
		
		return false	// Default to false to have data processing continue
	}
}



/*
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
        }
    }
}
*/

/*
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
            guard let response = response as? HTTPURLResponse else {
                print( "No response returned" )
                return
            }
            guard response.statusCode == 200 else {
                print( "Status code error: \(response.statusCode)" )
                return
            }
            guard response.mimeType == "text/html" || response.mimeType == "text/plain" else {
                print( "Unexpected response returned" )
                return
            }
            guard let data = data else {
                print( "No returned data" )
                return
            }

            let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print( dataString ?? "Unexpected data received" )
        })
        
        task.resume()
    }

}
*/
