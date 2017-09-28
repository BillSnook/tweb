//
//  listen.swift
//  tweb
//
//  Created by William Snook on 9/28/17.
//

import Foundation

import Foundation
#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif


class Listen {
	
	var target: Host?
	
#if	os(Linux)
	let socketfd = socket( AF_INET, Int32(SOCK_STREAM.rawValue), 0 )
#else
	let socketfd = socket( AF_INET, SOCK_STREAM, 0 )
#endif
	

	func doRcv( on port: UInt16 ) {
		let newsocket = getConnector( on: port )
		if newsocket < 0 {
			print( "Failed accepting socket" )
			return
		}
		print( "Got listener socket\n" )
		
		doWait( newSocket: newsocket )
		
		close( newsocket )
	}
	
	
	func getConnector( on port: UInt16 ) -> Int32 {
		#if	os(Linux)
			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: htons(port), sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#else
			var serv_addr_in = sockaddr_in( sin_family: sa_family_t(AF_INET), sin_port: port, sin_addr: in_addr( s_addr: INADDR_ANY ), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0) )
		#endif

		print( "\n\nIn getConnection before calling bind\n" )
		let bindResult = withUnsafeMutablePointer(to: &serv_addr_in) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				bind(socketfd, $0, socklen_t(MemoryLayout.size(ofValue: serv_addr_in)))
			}
		}
		print( "\nIn getConnection with bindResult: \(bindResult)\n" )
		if bindResult < 0 {
			print("\n\nERROR binding, errno: \(errno)")
			return bindResult
		}
		listen( socketfd, 5 )
		
		var cli_addr: sockaddr_in
		let cli_len = socklen_t(MemoryLayout.size(ofValue: cli_addr))
		
//		let newsockfd = withUnsafeMutablePointer(to: &cli_addr) {
//			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//				accept(socketfd, $0, socklen_t(MemoryLayout.size(ofValue: cli_addr)))
//			}
//		}
		let newsockfd = withUnsafeMutablePointer(to: &cli_addr) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				connect(socketfd, $0, cli_len)
			}
		}
		if newsockfd < 0 {
			print("\n\nERROR accepting, errno: \(errno)")
		}

		return newsockfd
	}
	
	
	func doWait( newSocket: Int32 ) {
		var buffer: [CChar] = [CChar](repeating: 0, count: 256)
		var n: ssize_t = 0
		while n < 255 {
			bzero( &buffer, 256 );
			n = read( newSocket, &buffer, 255 );
			if (n < 0) {
				print("\n\nERROR reading from newsocket")
			}
			if (n > 0) {
				n = write( newSocket, "OK", 2);
				if (n < 0) {
					print("\n\nERROR writing to socket");
				}
			}
			print("\(buffer)");
		}
		
	}
}

/*
long n = 0;
int sockfd, newsockfd, portno;
char buffer[256];
struct sockaddr_in serv_addr, cli_addr;
socklen_t clilen = sizeof(cli_addr);

sockfd = socket(AF_INET, SOCK_STREAM, 0);
if (sockfd < 0)
error("ERROR opening socket");
bzero((char *) &serv_addr, sizeof(serv_addr));
portno = CONNECTION_PORT; // atoi(argv[1]);
serv_addr.sin_family = AF_INET;
serv_addr.sin_addr.s_addr = INADDR_ANY;
serv_addr.sin_port = htons(portno);
if (bind(sockfd, (struct sockaddr *) &serv_addr,
sizeof(serv_addr)) < 0)
error("ERROR on binding");
listen(sockfd,5);

newsockfd = accept(sockfd,
(struct sockaddr *) &cli_addr,
&clilen);
if (newsockfd < 0)
error("ERROR on accept");

messagesInit();

while ( n < 255 ) {
	bzero(buffer,256);
	n = read(newsockfd,buffer,255);
	if (n < 0)
	error("ERROR reading from socket");
	// TODO: handle message here
	if ( n > 0 ) {
		messageHandler( buffer );
		n = write(newsockfd,"OK",2);
		if (n < 0)
		error("ERROR writing to socket");
	}
}

close(newsockfd);
close(sockfd);
*/
