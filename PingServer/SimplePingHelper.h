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

@interface SimplePingHelper : NSObject <SimplePingDelegate>
- (void)runWithHostName:(NSString *)hostName;


@end
