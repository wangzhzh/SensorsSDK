//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#include <sys/sysctl.h>
#import "SensorsAnalyticsSDK.h"

#define VERSION @"1.0.0"

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) NSDictionary *automaticProperties;
@property (nonatomic, assign) BOOL applicationWillResignActive;
@end

@implementation SensorsAnalyticsSDK

+ (SensorsAnalyticsSDK *)sharedInstance {
    static SensorsAnalyticsSDK *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"initSensorsSDK");
        sharedInstance = [[SensorsAnalyticsSDK alloc] initSensorsSDK];
    });
    return sharedInstance;
}

- (instancetype)initSensorsSDK {
    self = [super init];
    if (self) {
        _applicationWillResignActive = NO;
        self.automaticProperties = [self collectAutomaticProperties];
        [self setUpListeners];
    }
    return self;
}

- (void)setUpListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    //监听 UIApplicationDidBecomeActiveNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    //监听 applicationWillResignActive 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    
    //监听 applicationDidEnterBackground 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
}

//触发 $AppStart 事件
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"applicationDidBecomeActive");
    if (_applicationWillResignActive) {
        _applicationWillResignActive = NO;
        return;
    }
    [self track:@"$AppStart" andProperties:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"applicationWillResignActive");
    _applicationWillResignActive = YES;
}

//触发 $AppEnd 事件
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"applicationDidEnterBackground");
    _applicationWillResignActive = NO;
    [self track:@"$AppEnd" andProperties:nil];
}

- (void)track:(NSString *)eventName andProperties:(NSDictionary *)properties {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    
    //event
    [eventProperties setObject:eventName forKey:@"event"];
    
    //time
    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    [eventProperties setObject:timeStamp forKey:@"time"];
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    
    [libProperties addEntriesFromDictionary:self.automaticProperties];
    
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

- (NSDictionary *)collectAutomaticProperties {
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setObject:@"iOS" forKey:@"$os"];
    [p setObject:@"iOS" forKey:@"$lib"];
    [p setObject:@"Apple" forKey:@"$manufacturer"];
    [p setObject:VERSION forKey:@"$lib_version"];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_version"];
    
    UIDevice *device = [UIDevice currentDevice];
    [p setObject:[device systemVersion] forKey:@"os_version"];
    
    [p setObject:[self deviceModel] forKey:@"$model"];
    return [p copy];
}

- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

@end
