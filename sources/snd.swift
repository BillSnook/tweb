//
//  snd.swift
//  tweb
//
//  Created by William Snook on 9/20/17.
//

import Foundation
import Glibc


// Get socket to send on
// Get target reference - hostname.local to ip addr - bonjour |? dns
// Server address from target ref stuff, set port number
// Connect
// Repeat
//   write
//   read - blocks for data, assumed to be a response
// EndRepeat?
// Close socket

class Snd {

	var target: Host?
	var socket: SocketPort?

	func lookup( name: String ) -> Host? {
		
		target = Host( name: name )
		guard target != nil else {
			print( "Lookup failed for \(name)" )
			return nil
		}
		let addrs = target!.addresses
		guard addrs.count > 0 else {
			print( "Host call succeeded but no addresses were returned" )
			return nil
		}
		
		print( "Host call succeeds, count: \(addrs.count)" )
		for addr in addrs {
			print( "  addr: \(addr)" )
		}
		for name in target!.names { // We're not getting names when looking up Pi devices
			print( "  name: \(name)" )
		}

		return target
	}
	
	func getSocket( _ socket: Int, address: Int ) -> Int {
		let portNo: UInt16 = 5555
		let serv_addr: sockaddr_in = sockaddr_in( sin_len: sizeof(sockaddr_in), sin_family: AF_INET, sin_port: htons(portNo), sin_addr: address, sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )

		let connectResult = connect(sockfd, &serv_addr, sizeof(sockaddr_in) )
		if connectResult < 0 {
			print("ERROR connecting");
		}
		
		return connectResult
	}
	

	func doSnd( to: String ) {
	
		guard let server = lookup( name: to ) else {
			print( "Lookup failed for \(to)" )
			return
		}
		let addrs = server.addresses
		guard addrs.count > 0 else {
			print( "No addresses returned for \(to)" )
			return
		}
		let addr = addrs.first!
		let socketfd: Int = socket( AF_INET, SOCK_STREAM, 0 )
		guard let connectResult = getSocket( socketfd, address: atoi(addr) ) else {
			print( "Could not connect to socket for \(addr)" )
			return
		}
		print( "Got socket" )
		
		var n: long = 0
		var buffer = malloc( 256 )
		while n < 255 {
			
			// TODO: check inputs here to see if message is to be set else prompt
			print("> ");
			bzero(buffer,256);
			fgets(buffer,255,stdin);    // Waits for input
			
			n = write(sockfd,buffer,strlen(buffer));
			if (n < 0) {
				error("ERROR writing to socket")
			}
			
			bzero(buffer,256);
			n = read(sockfd,buffer,255);
			if (n < 0) {
				error("ERROR reading from socket")
			}
			
			print("%s\n",buffer);
		}
		// Clean up
		free( buffer )
		close( socketfd )
	}
}



/*
int sockfd, portno;
long n = 0;
struct sockaddr_in serv_addr;
struct hostent *server;

char buffer[256];
portno = CONNECTION_PORT;
sockfd = socket(AF_INET, SOCK_STREAM, 0);
if (sockfd < 0)
error("ERROR opening socket");
server = gethostbyname( CONNECTION_LISTENER ); // "localhost" ); // "workpi.local" );
if (server == NULL) {
	fprintf(stderr,"ERROR, no such host\n");
	exit(0);
}
bzero((char *) &serv_addr, sizeof(serv_addr));
serv_addr.sin_family = AF_INET;
bcopy((char *)server->h_addr,
      (char *)&serv_addr.sin_addr.s_addr,
      server->h_length);
serv_addr.sin_port = htons(portno);
if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0)
error("ERROR connecting");

while ( n < 255 ) {
	// TODO: check inputs here to see if message is to be set else prompt
	printf("> ");
	bzero(buffer,256);
	fgets(buffer,255,stdin);    // Waits for input
	
	n = write(sockfd,buffer,strlen(buffer));
	if (n < 0)
	error("ERROR writing to socket");
	bzero(buffer,256);
	n = read(sockfd,buffer,255);
	if (n < 0)
	error("ERROR reading from socket");
	
//        printf("%s\n",buffer);
}

close(sockfd);
return 0;
*/
