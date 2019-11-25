//
//  AppDelegate.m
//  Demo
//
//  Created by 张敏超🍎 on 2019/11/6.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "AppDelegate.h"
#import <SensorsSDK/SensorsSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [[SensorsAnalyticsSDK sharedInstance] track:@"AppStart" properties:@{@"testKey" : @"testValue"}];

    return YES;
}

@end
