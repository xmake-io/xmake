//
//  AppDelegate.m
//  test3
//
//  Created by ruki on 2020/4/4.
//  Copyright © 2020 tboox. All rights reserved.
//

#import "AppDelegate.h"
#import <test/test.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    int c = add(1, 2);
    NSLog(@"result: %d", c);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
