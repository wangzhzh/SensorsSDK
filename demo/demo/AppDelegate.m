//
//  AppDelegate.m
//  Demo
//
//  Created by 张敏超🍎 on 2019/11/6.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "AppDelegate.h"
#import <SensorsSDK/SensorsSDK.h>
#ifdef DEBUG
#import "SensorsDataReleaseObject.h"
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [[SensorsAnalyticsSDK sharedInstance] track:@"AppStart" properties:@{@"testKey" : @"testValue"}];

//    NSArray *array = @[@"first", @"second"];
//    NSLog(@"%@", array[2]);

#ifdef DEBUG
    NSString *crashedReason = [[NSUserDefaults standardUserDefaults] stringForKey:@"sensorsdata_app_crashed_reason"];
    if (crashedReason) {
        NSLog(@"%@", crashedReason);
    } else {
        SensorsDataReleaseObject *obj = [[SensorsDataReleaseObject alloc] init];
        [obj signalCrash];
    }
#endif

    return YES;
}

@end
