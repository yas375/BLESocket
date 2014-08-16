//
//  VIAppDelegate.m
//  BLESocket
//
//  Created by Victor Ilyukevich on 8/16/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "VIAppDelegate.h"

@implementation VIAppDelegate

#pragma mark - Methods

- (void)setupLogging
{
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setupLogging];
  return YES;
}

@end
