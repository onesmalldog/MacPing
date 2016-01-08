//
//  ViewController.m
//  PingServer
//
//  Created by YourtionGuo on 12/22/15.
//  Copyright © 2015 Yourtion. All rights reserved.
//

#import "ViewController.h"
#import "SimplePingHelper.h"


@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [NSThread detachNewThreadSelector:@selector(ping) toTarget:self withObject:nil];
    [SimplePingHelper ping:@"baidu.com" callback:^(BOOL succeed, NSTimeInterval time) {
        NSLog(@"%hhd, %f", succeed, time);
    }];
    [SimplePingHelper ping:@"taobao.com" callback:^(BOOL succeed, NSTimeInterval time) {
        NSLog(@"%hhd, %f", succeed, time);
    }];
    [SimplePingHelper ping:@"yourtion.com" callback:^(BOOL succeed, NSTimeInterval time) {
        NSLog(@"%hhd, %f", succeed, time);
    }];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end
