//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"

@implementation SensorsAnalyticsSDK

+ (SensorsAnalyticsSDK *)sharedInstance {
    static SensorsAnalyticsSDK *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"init");
        sharedInstance = [[SensorsAnalyticsSDK alloc] initSensorsSDK];
    });
    return sharedInstance;
}

- (instancetype)initSensorsSDK {
    self = [super init];
    if (self) {
        [self setUpListeners];
    }
    return self;
}

- (void)setUpListeners {
    // 监听 App 启动事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self track:@"$AppStart" andProperties:nil];
}

- (void)track:(NSString *)eventName andProperties:(NSDictionary *)properties {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    
    //event
    [eventProperties setObject:eventName forKey:@"event"];
    
    //time
    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    [eventProperties setObject:timeStamp forKey:@"time"];
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    
    //$os
    [libProperties setObject:@"iOS" forKey:@"$os"];
    
    //properties
    if (properties) {
        [libProperties addEntriesFromDictionary:properties];
    }
    
    [eventProperties setObject:libProperties forKey:@"properties"];
    
    //print
    NSString *logString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:eventProperties options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", logString);
}

+ (UInt64)getCurrentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

@end
