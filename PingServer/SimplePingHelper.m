//
//  SimplePingHelper.m
//  PingServer
//
//  Created by YourtionGuo on 12/22/15.
//  Copyright © 2015 Yourtion. All rights reserved.
//

#import "SimplePingHelper.h"
#include <sys/socket.h>
#include <netdb.h>

#pragma mark * Utilities

static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr)
// within the address NSData).
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    
    return result;
}

@interface SimplePingHelper()<SimplePingDelegate>
@property (nonatomic, strong) SimplePing *   pinger;
@property (nonatomic, strong) NSTimer *      sendTimer;
@property (nonatomic, strong) NSDate *       start;
@end

@implementation SimplePingHelper

@synthesize pinger    = _pinger;
@synthesize sendTimer = _sendTimer;

- (void)dealloc
{
    [self->_pinger stop];
    [self->_sendTimer invalidate];
}

- (NSString *)shortErrorFromError:(NSError *)error
// Given an NSError, returns a short error string that we can print, handling
// some special cases along the way.
{
    NSString *      result;
    NSNumber *      failureNum;
    int             failure;
    const char *    failureStr;
    
    assert(error != nil);
    
    result = nil;
    
    // Handle DNS errors as a special case.
    
    if ( [[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown) ) {
        failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        if ( [failureNum isKindOfClass:[NSNumber class]] ) {
            failure = [failureNum intValue];
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = [NSString stringWithUTF8String:failureStr];
                    assert(result != nil);
                }
            }
        }
    }
    
    // Otherwise try various properties of the error object.
    
    if (result == nil) {
        result = [error localizedFailureReason];
    }
    if (result == nil) {
        result = [error localizedDescription];
    }
    if (result == nil) {
        result = [error description];
    }
    assert(result != nil);
    return result;
}

- (void)runWithHostName:(NSString *)hostName
// The Objective-C 'main' for this program.  It creates a SimplePing object
// and runs the runloop sending pings and printing the results.
{
    assert(self.pinger == nil);
    
    self.pinger = [SimplePing simplePingWithHostName:hostName];
    assert(self.pinger != nil);
    
    self.pinger.delegate = self;
    [self.pinger start];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (self.pinger != nil);
}

+ (void)ping:(NSString*)address {
    [SimplePingHelper ping:address interval:1];
}

+ (void)ping:(NSString*)address interval:(NSInteger)interval {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        SimplePingHelper *helper = [[SimplePingHelper alloc] init];
        helper.interval = interval;
        [helper runWithHostName:address];
    });
}
- (void)sendPing
// Called to send a ping, both directly (as soon as the SimplePing object starts up)
// and via a timer (to continue sending pings periodically).
{
    assert(self.pinger != nil);
    self.start = [NSDate date];
    [self.pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
// A SimplePing delegate callback method.  We respond to the startup by sending a
// ping immediately and starting a timer to continue sending them every second.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    
    NSLog(@"pinging %@", DisplayAddressForAddress(address));
    
    // Send the first ping straight away.
    
    [self sendPing];
    
    // And start a timer to send the subsequent pings.
    
    assert(self.sendTimer == nil);
    NSInteger interval = self.interval ? : 1.0;
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
// A SimplePing delegate callback method.  We shut down our timer and the
// SimplePing object itself, which causes the runloop code to exit.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(error)
    NSLog(@"failed: %@", [self shortErrorFromError:error]);
    
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    
    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.
    
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the send.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u sent", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber) );
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
// A SimplePing delegate callback method.  We just log the failure.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
#pragma unused(error)
    NSLog(@"#%u send failed: %@", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber), [self shortErrorFromError:error]);
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the reception of a ping response.
{
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"%@ #%u received", pinger.hostName ,(unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber) );
    NSTimeInterval time = [self.start timeIntervalSinceNow];
    NSLog(@"%@  time : %f ms", pinger.hostName ,time * -1000);
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the receive.
{
    const ICMPHeader *  icmpPtr;
    
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    
    icmpPtr = [SimplePing icmpInPacket:packet];
    if (icmpPtr != NULL) {
        NSLog(@"#%u unexpected ICMP type=%u, code=%u, identifier=%u", (unsigned int) OSSwapBigToHostInt16(icmpPtr->sequenceNumber), (unsigned int) icmpPtr->type, (unsigned int) icmpPtr->code, (unsigned int) OSSwapBigToHostInt16(icmpPtr->identifier) );
    } else {
        NSLog(@"unexpected packet size=%zu", (size_t) [packet length]);
    }
}

@end
