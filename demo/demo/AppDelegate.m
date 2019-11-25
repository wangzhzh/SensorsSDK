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

static NSString * const kGroupIdentifier = @"group.com.wangzhzh.demo.extension";

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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[SensorsAnalyticsSDK sharedInstance] trackFromAppExtensionForApplicationGroupIdentifier:kGroupIdentifier];
}

@end
