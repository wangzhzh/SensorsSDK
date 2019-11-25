//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/6.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"
#import "UIView+SensorsData.h"
#include <sys/sysctl.h>

static NSString * const kVersion = @"1.0.0";

static NSString * const SensorsAnalyticsEventBeginKey = @"event_begin";
static NSString * const SensorsAnalyticsEventDurationKey = @"event_duration";
static NSString * const SensorsAnalyticsEventIsPauseKey = @"is_pause";
static NSString * const SensorsAnalyticsEventDidEnterBackgroundKey = @"did_enter_background";

@interface SensorsAnalyticsSDK ()

/// 由 SDK 自动采集的事件属性，即预置属性
@property (nonatomic, strong) NSDictionary<NSString *, id> *automaticProperties;

/// 标记应用程序是否将进入非活跃状态
@property (nonatomic) BOOL applicationWillResignActive;
/// 是否为被动启动
@property (nonatomic, getter=isLaunchedPassively) BOOL launchedPassively;
/// 保存被动启动时触发的事件
@property (nonatomic, strong) NSMutableArray *passivelyEvents;

/// 保存进入后台时，未暂停的事件
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;
/// 事件时长计算
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimer;

@end

@implementation SensorsAnalyticsSDK

+ (SensorsAnalyticsSDK *)sharedInstance {
    static dispatch_once_t onceToken;
    static SensorsAnalyticsSDK *sdk = nil;
    dispatch_once(&onceToken, ^{
        sdk = [[SensorsAnalyticsSDK alloc] init];
    });
    return sdk;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _passivelyEvents = [NSMutableArray array];
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        _trackTimer = [NSMutableDictionary dictionary];

        _automaticProperties = [self collectAutomaticProperties];

        // 添加应用程序状态监听
        [self setupListeners];
    }
    return self;
}

- (void)printEvent:(NSDictionary *)event {
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"JSON Serialized Error: %@", error);
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[Event]: %@", json);
#endif
}

#pragma mark - Property
+ (double)currentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (double)systemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (NSDictionary<NSString *, id> *)collectAutomaticProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 设置系统
    properties[@"$os"] = @"iOS";
    // 设置 SDK 的平台
    properties[@"$lib"] = @"iOS";
    // 设置生产商
    properties[@"$manufacturer"] = @"iOS";
    // 设置 SDK 的版本
    properties[@"$lib_version"] = kVersion;
    // 设置本机型号
    properties[@"$model"] = [self deviceModel];
    // 设置系统版本
    properties[@"os_version"] = UIDevice.currentDevice.systemVersion;
    // 设置应用版本
    properties[@"$app_version"] = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return [properties copy];
}

/// 获取手机型号
- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

#pragma mark - Application lifecycle

- (void)setupListeners {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    //监听 UIApplicationDidFinishLaunchingNotification
    [center addObserver:self
               selector:@selector(applicationDidFinishLaunching:)
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];

    // 监听 UIApplicationDidEnterBackgroundNotification，即当应用程序进入后台之后会调用通知方法
    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];

    // 监听 UIApplicationDidBecomeActiveNotification，即当应用程序进入进入前台并处于活动状态时，会调用通知方法
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    // 监听 UIApplicationWillResignActiveNotification，即当应用程序进入进入前台并处于活动状态时，会调用通知方法
    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"Application did finish launching.");

    // 当应用程序处于 UIApplicationStateBackground 状态时，说明应用程序启动是被动启动
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        // 触发被动启动事件
        [self track:@"$AppStartPassively" properties:nil];
        // 设置被动起动标记
        self.launchedPassively = YES;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"Application did enter background.");

    self.applicationWillResignActive = NO;

    // 触发 $AppEnd 事件
//    [self track:@"$AppEnd" properties:nil];
    [self trackTimerEnd:@"$AppEnd" properties:nil];

    // 暂停所有事件时长统计
    [self.trackTimer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj[SensorsAnalyticsEventIsPauseKey] boolValue]) {
            [self.enterBackgroundTrackTimerEvents addObject:key];
            [self trackTimerPause:key];
        }
    }];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"Application did become active.");

    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }

    // 当应用程序处于被动启动
    if (self.launchedPassively) {
        // 处理被动启动期间触发的所有事件
        for (NSDictionary *event in self.passivelyEvents) {
            [self printEvent:event];
        }
    }
    // 将被动启动标记设为 NO，正常记录事件
    self.launchedPassively = NO;

    // 触发 $AppStart 事件
    [self track:@"$AppStart" properties:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"Application will resign active.");
    self.applicationWillResignActive = YES;
}

@end

@implementation SensorsAnalyticsSDK (Track)

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *,id> *)properties {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    // 设置事件名称
    event[@"event"] = eventName;
    // 设置事件发生的时间戳，单位为：毫秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 * 1000];

    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 判断是否为被动启动状态下
    if (self.launchedPassively) {
        // 添加应用程序状态属性
        eventProperties[@"$app_state"] = @"background";
    }
    // 设置事件属性
    event[@"properties"] = eventProperties;

    // 判断是否为被动启动过程中记录的事件，不包含被动启动事件
    if (self.launchedPassively && ![eventName isEqualToString:@"$AppStartPassively"]) {
        // 保存被动启动状态下记录的事件
        [self.passivelyEvents addObject:eventProperties];
        return;
    }

    [self printEvent:event];
}

- (void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 获取控件类型
    eventProperties[@"$element_type"] = view.sensorsdata_elementType;
    // 获取控件显示文本
    eventProperties[@"$element_content"] = view.sensorsdata_elementContent;

    // 获取控件所在的 UIViewController
    UIViewController *vc = view.sensorsdata_viewController;
    // 设置页面相关属性
    eventProperties[@"$screen_name"] = NSStringFromClass(vc.class);

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}

- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];

    // TODO: 获取用户点击的 UITableViewCell 控件对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // TODO: 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    eventProperties[@"$element_content"] = cell.sensorsdata_elementContent;
    // TODO: 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    eventProperties[@"$element_position"] = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:tableView properties:eventProperties];
}

- (void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];

    // 获取用户点击的 UITableViewCell 控件对象
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    // 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    eventProperties[@"$element_content"] = cell.sensorsdata_elementContent;
    // 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    eventProperties[@"$element_position"] = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];

    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:collectionView properties:eventProperties];
}

@end

#pragma mark - Timer
@implementation SensorsAnalyticsSDK (Timer)

- (void)trackTimerStart:(NSString *)event {
    // 记录事件开始时间 -> 记录事件开始时系统启动时间
    self.trackTimer[event] = @{SensorsAnalyticsEventBeginKey: @([SensorsAnalyticsSDK systemUpTime])};
}

- (void)trackTimerPause:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    // 如果该事件时长统计已经暂停，直接返回，不做任何处理
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    // 获取当前系统启动时间
    double systemUpTime = [SensorsAnalyticsSDK systemUpTime];
    // 获取开始时间
    double beginTime = [eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
    // 计算暂停前统计的时长
    double duration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue] + systemUpTime - beginTime;
    eventTimer[SensorsAnalyticsEventDurationKey] = @(duration);
    // 事件处于暂停状态
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(YES);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerResume:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    // 如果该事件时长统计没有暂停，直接返回，不做任何处理
    if (![eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    // 获取当前系统启动时间
    double systemUpTime = [SensorsAnalyticsSDK systemUpTime];
    // 重置事件开始时间
    eventTimer[SensorsAnalyticsEventBeginKey] = @(systemUpTime);
    // 将事件暂停标记设置为 NO
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(NO);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerEnd:(NSString *)event properties:(NSDictionary *)properties {
    NSDictionary *eventTimer = self.trackTimer[event];
    if (!eventTimer) {
        return [self track:event properties:properties];
    }

    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:properties];
    // 移除
    [self.trackTimer removeObjectForKey:event];

    // 如果该事件时长统计没有暂停，直接返回，不做任何处理
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        // 获取事件时长
        double eventDuration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        // 设置事件时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3lf", eventDuration] floatValue]);
    } else {
        // 事件开始时间
        double beginTime = [(NSNumber *)eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
        // 获取当前时间 -> 获取当前系统启动时间
        double currentTime = [SensorsAnalyticsSDK systemUpTime];
        // 计算事件时长
        double eventDuration = currentTime - beginTime + [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        // 设置事件时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3lf", eventDuration] floatValue]);
    }

    // 触发事件
    [self track:event properties:p];
}

@end
