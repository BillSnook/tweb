//
//  snd.swift
//  tweb
//
//  Created by William Snook on 9/20/17.
//

import Foundation


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
		return target
	}
	
	func getSocket() -> SocketPort? {
		
		
		return nil
	}
	
	func doSnd( to: String ) {
	
		guard let server = lookup( name: to ) as! Host else {
			print( "Lookup fails: \(addrs.count)" )
			return
		}
		let addrs = server.addresses
		guard addrs != nil && addrs.count > 0 else { return }
		
		print( "Lookup succeeds, count: \(addrs.count)" )
		for addr in addrs {
			print( "  \(addr.address)" )
		}
		for name in server.names {
			print( "  name: \(name)" )
		}

//		let useAddr = addrs.first
		
		
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
