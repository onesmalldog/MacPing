//
//  SimplePingHelper.h
//  PingServer
//
//  Created by YourtionGuo on 12/22/15.
//  Copyright © 2015 Yourtion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

#include <sys/socket.h>
#include <netdb.h>

typedef void (^SimplePingCallback) (BOOL succeed,NSTimeInterval time);

@interface SimplePingHelper : NSObject <SimplePingDelegate>
@property (nonatomic) NSInteger interval;
+ (void)ping:(NSString*)address callback:(SimplePingCallback)callback;
+ (void)ping:(NSString*)address interval:(NSInteger)interval callback:(SimplePingCallback)callback;
@end
