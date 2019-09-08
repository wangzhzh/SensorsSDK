//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#include <sys/sysctl.h>
#import "SensorsAnalyticsSDK.h"
#import "UITableView+SensorsData.h"
#import "UICollectionView+SensorsData.h"
#import "UIApplication+SensorsData.h"
#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsExceptionHandler.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsFileStore.h"
#import "SensorsAnalyticsDatabase.h"

#define VERSION @"1.0.0"

static NSString *SensorsAnalyticsEventBeginKey = @"event_begin";
static NSString *SensorsAnalyticsEventDurationKey = @"event_duration";
static NSString *SensorsAnalyticsEventIsPauseKey = @"is_pause";
static NSString *SensorsAnalyticsEventDidEnterBackgroundKey = @"did_enter_background";

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) NSDictionary *automaticProperties;

@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;
/// 保存被动启动时触发的事件
@property (nonatomic, strong) NSMutableArray *passivelyEvents;

@property (nonatomic, assign) BOOL applicationWillResignActive;
@property (nonatomic, assign) BOOL appRelaunched;

/// 保存进入后台时，未暂停的事件
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;
/// 事件时长计算
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimer;

/// 文件缓存事件数据对象
@property (nonatomic, strong) SensorsAnalyticsFileStore *fileStore;

/// 数据库存储对象
@property (nonatomic, strong) SensorsAnalyticsDatabase *database;

@end

@implementation SensorsAnalyticsSDK

+ (SensorsAnalyticsSDK *)sharedInstance {
    static SensorsAnalyticsSDK *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"initSensorsSDK");
        sharedInstance = [[SensorsAnalyticsSDK alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 获取主线程
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_block_t block = ^ {
            // 当 App 处于 UIApplicationStateBackground 状态时，应用是被动启动
            self.launchedPassively = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
        };
        // 判断当前线程是否为主线程
        if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(mainQueue)) == 0) {
            block();
        } else {
            dispatch_sync(mainQueue, block);
        }
        _applicationWillResignActive = NO;
        _appRelaunched = NO;
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        _trackTimer = [NSMutableDictionary dictionary];
        self.automaticProperties = [self collectAutomaticProperties];
        [self setUpListeners];
        [UITableView swizzleUITableView];
        [UICollectionView swizzleCollectionView];
        [UIViewController swizzleUIViewController];
//        [UIApplication swizzleUIApplication];
        // 调用异常处理单例对象，进行初始化
        [SensorsAnalyticsExceptionHandler sharedInstance];

        _fileStore = [[SensorsAnalyticsFileStore alloc] init];
        NSLog(@"%ld", [_fileStore allEvents].count);
//        [_fileStore deleteEventsForCount:10];
//        NSLog(@"%ld", [_fileStore allEvents].count);

        // 初始化 SensorsAnalyticsDatabase 类的对象，使用默认路径
        _database = [[SensorsAnalyticsDatabase alloc] init];
        NSLog(@"%@", [_database selectEventsForCount:50]);
        [_database deleteEventsForCount:2];
        NSLog(@"%@", [_database selectEventsForCount:50]);
    }
    return self;
}

- (void)sensorsdata_execute:(UIControl *)sender {
//    NSLog(@"Function: %s, Sender: %@, Event: %@", __FUNCTION__, sender, event);
    NSLog(@"-----");
}

- (void)setUpListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    //监听 UIApplicationDidFinishLaunchingNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidFinishLaunching:)
                               name:UIApplicationDidFinishLaunchingNotification
                             object:nil];
    
    //监听 UIApplicationWillEnterForegroundNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    //监听 UIApplicationDidEnterBackgroundNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    //监听 UIApplicationDidBecomeActiveNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    //监听 UIApplicationWillResignActiveNotification 本地通知
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    NSLog(@"applicationWillEnterForeground");
    _appRelaunched = YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"applicationDidFinishLaunching");
    if (self.launchedPassively) {
        [self track:@"$AppStartPassively" properties:nil];
    }
}

// 触发 $AppStart 事件
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"applicationDidBecomeActive");
    if (_applicationWillResignActive) {
        _applicationWillResignActive = NO;
        return;
    }

    // 当内存中保存了被动启动过程中记录的事件时，进行上传
    if (self.passivelyEvents.count > 0) {
        for (NSDictionary *event in self.passivelyEvents) {
//            [_fileStore saveEvent:event];
            [_database insertEvent:event];
        }
        // 将被动启动标记设为 NO，正常记录事件
        self.launchedPassively = NO;
    }

    if (_appRelaunched) {
        [self track:@"$AppStart" properties:nil];
    }

    // 恢复所有事件时长统计
    for (NSString *event in self.enterBackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    [self.enterBackgroundTrackTimerEvents removeAllObjects];

    // 开始 $AppEnd 事件计时
    [self trackTimerStart:@"$AppEnd"];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"applicationWillResignActive");
    _applicationWillResignActive = YES;
}

// 触发 $AppEnd 事件
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"applicationDidEnterBackground");
    _applicationWillResignActive = NO;
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

- (void)track:(NSString *)eventName properties:(NSDictionary *)properties {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    
    //event
    [eventProperties setObject:eventName forKey:@"event"];
    
    //time
    NSNumber *timeStamp = @([SensorsAnalyticsSDK currentTime]);
    [eventProperties setObject:timeStamp forKey:@"time"];
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    
    [libProperties addEntriesFromDictionary:self.automaticProperties];
    
    //properties
    if (properties) {
        [libProperties addEntriesFromDictionary:properties];
    }
    
    [eventProperties setObject:libProperties forKey:@"properties"];
    NSLog(@"[Event]: %@", eventProperties);

    // 判断是否为被动启动过程中记录的事件，不包含被动启动事件
    if (self.launchedPassively && ![eventName isEqualToString:@"$AppStartPassively"]) {
        if (!self.passivelyEvents) {
            self.passivelyEvents = [NSMutableArray array];
        }
        // 保存被动启动状态下记录的事件
        [self.passivelyEvents addObject:eventProperties];
    } else {
//        [_fileStore saveEvent:eventProperties];
        [_database insertEvent:eventProperties];
    }
}

+ (double)currentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (double)systemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
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

@implementation SensorsAnalyticsSDK (AppClick)

- (void)trackAppClickWithView:(UIView *)view {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 获取控件显示文本
    properties[@"$element_content"] = view.sensorsdata_elementContent;
    // 获取控件类型
    properties[@"$element_type"] = NSStringFromClass([view class]);
    // 获取所属 UIViewController
    properties[@"screen_name"] = NSStringFromClass([view.sensorsdata_viewController class]);
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

- (void)trackTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 初始化 properties 字典对象
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // 设置控件类型（$element_type）
    properties[@"$element_type"] = NSStringFromClass([tableView class]);
    // TODO: 获取用户点击的 UITableViewCell 控件对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // TODO: 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    properties[@"$element_content"] = cell.sensorsdata_elementContent;
    // TODO: 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    properties[@"$element_position"] = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    // 设置 screen_name 属性
    properties[@"screen_name"] = NSStringFromClass([tableView.sensorsdata_viewController class]);
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

- (void)trackCollectionView:(UICollectionView *)collectionView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 初始化 properties 字典对象
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // 设置控件类型（$element_type）
    properties[@"$element_type"] = NSStringFromClass([collectionView class]);
    // TODO: 获取用户点击的 UITableViewCell 控件对象
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    // TODO: 设置被用户点击的 UITableViewCell 控件上的内容（$element_content）
    properties[@"$element_content"] = cell.sensorsdata_elementContent;
    // TODO: 设置被用户点击的 UITableViewCell 控件所在的位置（$element_position）
    properties[@"$element_position"] = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    // 设置 screen_name 属性
    properties[@"screen_name"] = NSStringFromClass([collectionView.sensorsdata_viewController class]);
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

@end


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
