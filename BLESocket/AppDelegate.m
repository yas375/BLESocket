//
//  AppDelegate.m
//  BLESocket
//
//  Created by Victor Ilyukevich on 8/16/14.
//  Copyright (c) 2014 Victor Ilyukevich. All rights reserved.
//

#import "AppDelegate.h"
#import <LumberjackConsole/PTEDashboard.h>
#import "SocketViewController.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface AppDelegate ()
<UISplitViewControllerDelegate>
@end

@implementation AppDelegate

#pragma mark - Methods

- (void)setupLogging
{
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  if (BluetoothDebuggingEnabled()) {
    [[PTEDashboard sharedDashboard] show];
  }
  DDLogInfo(@"Added console dashboard");
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setupLogging];

  UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
  UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
  navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
  splitViewController.delegate = self;

  return YES;
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
  if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[SocketViewController class]] && ([(SocketViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
    // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
    return YES;
  } else {
    return NO;
  }
}

@end
