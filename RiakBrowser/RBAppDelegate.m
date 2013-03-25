//
//  RBAppDelegate.m
//  RiakBrowser
//
//  Created by ilja on 24.03.13.
//  Copyright (c) 2013 iwascoding. All rights reserved.
//

#import "RBAppDelegate.h"

#import "AFHTTPRequestOperationLogger.h"

@implementation RBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[AFHTTPRequestOperationLogger sharedLogger] startLogging];
	[[AFHTTPRequestOperationLogger sharedLogger] setLevel:AFLoggerLevelDebug];}

@end
