//
//  MPNetReach.m
//  MPLibrary
//
//  Created by Heizer, Charles on 5/30/14.
//
//

#import "MPNetReach.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define DEFAULT_TIMEOUT 10

@interface MPNetReach ()

- (int)isAlive:(struct sockaddr_in)scanaddr;

@end

@implementation MPNetReach

- (id)init
{
    return [self initWithTimeout:DEFAULT_TIMEOUT];
}

- (id)initWithTimeout:(int)aTimeout
{
    self = [super init];
    if (self) {
        self.timeout = aTimeout;
    }
    return self;
}

- (BOOL)isMPServerAlive:(int)aPort host:(NSString *)aHost
{
	@try
    {
        const char *addr = [aHost cStringUsingEncoding:NSASCIIStringEncoding];

        short int sock = -1;        // the socket descriptor
        struct hostent *host_info;  // host info structure
        struct sockaddr_in address; // address structures

        bzero((char *)&address, sizeof(address));  // init addr struct
        address.sin_addr.s_addr = inet_addr(addr); // assign the address
        address.sin_port = htons(aPort);           // translate int2port num

        // Hostname resolution
        if ((host_info = gethostbyname(addr))) {
            bcopy(host_info->h_addr,(char *)&address.sin_addr,host_info->h_length);
        } else if ((address.sin_addr.s_addr = inet_addr(addr)) == INADDR_NONE) {
            qlinfo(@"Could not resolve host, %@",aHost);
            return NO;
        }

        if ([self isAlive:address] != 0) {
            return NO;
        }

        // So far so good - the host exists and is up; check the port and report
        close (sock);
        sock = socket(AF_INET, SOCK_STREAM, 0);
        if (connect(sock,(struct sockaddr *)&address,sizeof(address)) == 0) {
            //printf("%i is open on %s\n", port, argv[2]);
            return YES;
        } else {
            //printf("%i is not open on %s\n", port, argv[2]);
            qlinfo(@"%d is not open on %@",aPort,aHost);
        }

        close(sock);
	}
	@catch (NSException * e) {
		qlerror(@"%@",[e description]);
	}

	return NO;
}

- (int)isAlive:(struct sockaddr_in)scanaddr
{
    short int sock;          /* our main socket */
    long arg;                /* for non-block */
    fd_set wset;             /* file handle for bloc mode */
    struct timeval timeout;  /* timeout struct for connect() */

    sock = -1;

    sock = socket(AF_INET, SOCK_STREAM, 0);

    if( (arg = fcntl(sock, F_GETFL, NULL)) < 0) {
        fprintf(stderr,"Error fcntl(..., F_GETFL) (%s)\n",strerror(errno));
        return 1;
    }

    arg |= O_NONBLOCK;
    if(fcntl(sock, F_SETFL, arg) < 0) {
        fprintf(stderr,"Error fcntl(..., F_SETFL)  (%s)\n",strerror(errno));
        return 1;
    }

    /*
     * set result stat then try a select if it can take
     * awhile. This is dirty but works
     */
    int res = connect(sock,(struct sockaddr *)&scanaddr, sizeof(scanaddr));

    if (res < 0) {
        if (errno == EINPROGRESS) {
            timeout.tv_sec = self.timeout;
            timeout.tv_usec = 0;
            FD_ZERO(&wset);
            FD_SET(sock, &wset);
            int rc = select(sock + 1, NULL, &wset, NULL, &timeout);

            /* This works great on dead hosts */
            if (rc == 0 && errno != EINTR) {
                //printf("Error connecting\n");
                close (sock);
                return 1;
            }
        }
    }
    close(sock);
    return 0;
}

@end