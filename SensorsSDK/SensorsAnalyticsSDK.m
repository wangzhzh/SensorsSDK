//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsFileStore.h"
#import "SensorsAnalyticsDatabase.h"
#import "SensorsAnalyticsNetwork.h"
#import "SensorsAnalyticsExceptionHandler.h"
#import "SensorsAnalyticsExtensionDataManager.h"
#import "SensorsAnalyticsKeychainItem.h"
#include <sys/sysctl.h>
#include <objc/runtime.h>

#ifndef SENSORS_ANALYTICS_UIWEBVIEW
#import <WebKit/WebKit.h>
#endif

static NSString * const SensorsAnalyticsVersion = @"1.0.0";

static NSString * const SensorsAnalyticsLoginId = @"cn.sensorsdata.login_id";
static NSString * const SensorsAnalyticsAnonymousId = @"cn.sensorsdata.anonymous_id";
static NSString * const SensorsAnalyticsKeychainService = @"cn.sensorsdata.SensorsAnalytics.id";

static NSString * const SensorsAnalyticsEventBeginKey = @"event_begin";
static NSString * const SensorsAnalyticsEventDurationKey = @"event_duration";
static NSString * const SensorsAnalyticsEventIsPauseKey = @"is_pause";
static NSString * const SensorsAnalyticsEventDidEnterBackgroundKey = @"did_enter_background";

// 默认上传事件条数
static NSUInteger const SensorsAnalyticsDefalutFlushEventCount = 50;

static NSString * const SensorsAnalyticsJavaScriptTrackEventScheme = @"sensorsanalytics://trackEvent";

@interface SensorsAnalyticsSDK ()

/// 由 SDK 自动采集的事件属性，即预置属性
@property (nonatomic, copy) NSDictionary<NSString *, id> *automaticProperties;

/// 标记应用程序是否将进入非活跃状态
@property (nonatomic) BOOL applicationWillResignActive;
/// 是否为被动启动
@property (nonatomic, getter=isLaunchedPassively) BOOL launchedPassively;
/// 保存被动启动时触发的事件
@property (nonatomic, strong) NSMutableArray *passivelyEvents;

/// 登录 ID
@property (nonatomic, copy) NSString *loginId;

/// 保存进入后台时，未暂停的事件
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;
/// 事件时长计算
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimer;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

/// 文件缓存事件数据对象
@property (nonatomic, strong) SensorsAnalyticsFileStore *fileStore;
/// 数据库存储对象
@property (nonatomic, strong) SensorsAnalyticsDatabase *database;

@property (nonatomic, strong) NSURL *serverURL;
/// 数据上传等网络请求对象
@property (nonatomic, strong) SensorsAnalyticsNetwork *network;
/// 定时上传事件的 Timer
@property (nonatomic, strong) NSTimer *flushTimer;

#ifndef SENSORS_ANALYTICS_UIWEBVIEW
// 由于 WKWebView 获取 UserAgent 是异步过程，为了在获取过程中创建的 WKWebView 对象不被销毁，需要保存创建的临时对象
@property (nonatomic, strong) WKWebView *webView;
#endif

@end

@implementation SensorsAnalyticsSDK {
    NSString *_anonymousId;
}

static SensorsAnalyticsSDK *sharedInstance = nil;
+ (void)startWithServerURL:(NSString *)urlString {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SensorsAnalyticsSDK alloc] initWithServerURL:urlString];
    });
}

+ (SensorsAnalyticsSDK *)sharedInstance {
    return sharedInstance;
}

- (instancetype)initWithServerURL:(NSString *)urlString {
    self = [super init];
    if (self) {
        _passivelyEvents = [NSMutableArray array];
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        _trackTimer = [NSMutableDictionary dictionary];

        _loginId = [[NSUserDefaults standardUserDefaults] objectForKey:SensorsAnalyticsLoginId];

        _automaticProperties = [self collectAutomaticProperties];
        // 设置是否被动启动标记
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;

        NSString *queueLabel = [NSString stringWithFormat:@"cn.sensorsdata.%@.%p", self.class, self];
        _serialQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);

        // 添加应用程序状态监听
        [self setupListeners];

        _fileStore = [[SensorsAnalyticsFileStore alloc] init];
        // 初始化 SensorsAnalyticsDatabase 类的对象，使用默认路径
        _database = [[SensorsAnalyticsDatabase alloc] init];

        _flushBulkSize = 100;
        _flushInterval = 15;
        _network = [[SensorsAnalyticsNetwork alloc] initWithServerURL:[NSURL URLWithString:urlString]];

        // 调用异常处理单例对象，进行初始化
        [SensorsAnalyticsExceptionHandler sharedInstance];

        [self startFlushTimer];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - FlushTimer

/// 开启上传数据的定时器
- (void)startFlushTimer {
    if (self.flushTimer) {
        return;
    }
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}

// 停止上传数据的定时器
- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
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
    properties[@"$lib_version"] = SensorsAnalyticsVersion;
    // 设置本机型号
    properties[@"$model"] = [self deviceModel];
    // 设置系统版本
    properties[@"$os_version"] = UIDevice.currentDevice.systemVersion;
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

- (void)setFlushInterval:(NSUInteger)flushInterval {
    if (_flushInterval != flushInterval) {
        _flushInterval = flushInterval;
        // 上传本地所有事件数据
        [self flush];
        // 先暂停计时器
        [self stopFlushTimer];
        // 重新开启定时器
        [self startFlushTimer];
    }
}

- (void)setAnonymousId:(NSString *)anonymousId {
    _anonymousId = anonymousId;
    // 保存设备 ID（匿名 ID）
    [self saveAnonymousId:anonymousId];
}

- (NSString *)anonymousId {
    if (_anonymousId) {
        return _anonymousId;
    }
    // 从 NSUserDefaults 中读取设备 ID
    _anonymousId = [[NSUserDefaults standardUserDefaults] objectForKey:SensorsAnalyticsAnonymousId];
    if (_anonymousId) {
        return _anonymousId;
    }

    SensorsAnalyticsKeychainItem *item = [[SensorsAnalyticsKeychainItem alloc] initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId];
    // 从 Keychain 中读取设备 ID
    _anonymousId = [item value];

    if (_anonymousId) {
        // 将设备 ID 保存在 NSUserDefaults 中
        [[NSUserDefaults standardUserDefaults] setObject:_anonymousId forKey:SensorsAnalyticsAnonymousId];
        // 返回保存的设备 ID
        return _anonymousId;
    }

    // 获取 IDFA
    Class cls = NSClassFromString(@"ASIdentifierManager");
    if (cls) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // 获取 ASIdentifierManager 的单利对象
        id manager = [cls performSelector:@selector(sharedManager)];
        SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL (*isAdvertisingTrackingEnabled)(id, SEL) = (BOOL (*)(id, SEL))[manager methodForSelector:selector];
        if (isAdvertisingTrackingEnabled(manager, selector)) {
            // 使用 IDFA 作为设备 ID
            _anonymousId = [(NSUUID *)[manager performSelector:@selector(advertisingIdentifier)] UUIDString];
        }
#pragma clang diagnostic pop
    }
    if (!_anonymousId) {
        // 使用 IDFV 作为设备 ID
        _anonymousId = UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    if (!_anonymousId) {
        // 使用 UUID 作为设备 ID
        _anonymousId = NSUUID.UUID.UUIDString;
    }
    
    // 保存设备 ID（匿名 ID）
    [self saveAnonymousId:_anonymousId];

    return _anonymousId;
}

- (void)saveAnonymousId:(NSString *)anonymousId {
    // 保存设备 ID
    [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:SensorsAnalyticsAnonymousId];
    [[NSUserDefaults standardUserDefaults] synchronize];

    SensorsAnalyticsKeychainItem *item = [[SensorsAnalyticsKeychainItem alloc] initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId];
    if (anonymousId) {
        // 当设备 ID（匿名 ID）不为空时，将其保存在 Keychain 中
        [item update:anonymousId];
    } else {
        // 当设备 ID（匿名 ID）为空时，将删除 Keychain 中的值
        [item remove];
    }
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

        // 当应用程序在后台运行时，触发被动启动事件
    if (self.isLaunchedPassively) {
        // 触发被动启动事件
        [self track:@"$AppStartPassively" properties:nil];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"Application did enter background.");

    self.applicationWillResignActive = NO;

    // 触发 $AppEnd 事件
//    [self track:@"$AppEnd" properties:nil];
    [self trackTimerEnd:@"$AppEnd" properties:nil];

    UIApplication *application = UIApplication.sharedApplication;
    // 初始化标识符
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^() {
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };
    // 标记长时间运行的后台任务
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];

    dispatch_async(self.serialQueue, ^{
        // 发送数据
        [self flushByEventCount:SensorsAnalyticsDefalutFlushEventCount background:YES];
        // 结束后台任务
        endBackgroundTask();
    });

    // 暂停所有事件时长统计
    [self.trackTimer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj[SensorsAnalyticsEventIsPauseKey] boolValue]) {
            [self.enterBackgroundTrackTimerEvents addObject:key];
            [self trackTimerPause:key];
        }
    }];

    // 停止计时器
    [self stopFlushTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"Application did become active.");

    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }

    // 当应用程序处于被动启动
    if (self.isLaunchedPassively) {
        // 处理被动启动期间触发的所有事件
        for (NSDictionary *event in self.passivelyEvents) {
            [self printEvent:event];
        }
    }
    // 将被动启动标记设为 NO，正常记录事件
    self.launchedPassively = NO;

    // 触发 $AppStart 事件
    [self track:@"$AppStart" properties:nil];

    // 恢复所有事件时长统计
    for (NSString *event in self.enterBackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    [self.enterBackgroundTrackTimerEvents removeAllObjects];
    // 开始 $AppEnd 事件计时
    [self trackTimerStart:@"$AppEnd"];

    // 开始计时器
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"Application will resign active.");
    self.applicationWillResignActive = YES;
}

#pragma mark - Login
- (void)login:(NSString *)loginId {
    self.loginId = loginId;
    // 在本地保存登录 ID
    [[NSUserDefaults standardUserDefaults] setObject:loginId forKey:SensorsAnalyticsLoginId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Flush

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        // 默认一次向服务端发送 50 条数据
        [self flushByEventCount:SensorsAnalyticsDefalutFlushEventCount background:NO];
    });
}

- (void)flushByEventCount:(NSUInteger)count background:(BOOL)background {
    if (background) {
        __block BOOL isContinue = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
            // 当运行时间大于于请求的超时时间时，为保证数据库删除时应用不被强杀，不再继续上传
            isContinue = UIApplication.sharedApplication.backgroundTimeRemaining >= 30;
        });
        if (!isContinue) {
            return;
        }
    }

    // 获取本地数据
    NSArray<NSString *> *events = [self.database selectEventsForCount:count];
    // 当本地存储的数据为 0 或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || ![self.network flushEvents:events]) {
        return;
    }
    // 当删除数据失败时，直接返回退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }

    // 继续上传本地的其他数据
    [self flushByEventCount:count background:background];
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

    // 设置事件的 distinct_id，用于唯一标识一个用户
    event[@"distinct_id"] = self.loginId ?: self.anonymousId;

    dispatch_async(self.serialQueue, ^{
        [self printEvent:event];
        [self.fileStore saveEvent:event];
        [self.database insertEvent:event];
    });

    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
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

- (void)trackFromAppExtensionForApplicationGroupIdentifier:(NSString *)identifier {
    dispatch_async(self.serialQueue, ^{
        // 获取 App Group Identifier 对应的应用扩展中采集的事件数据
        NSArray *allEvents = [[SensorsAnalyticsExtensionDataManager sharedInstance] allEventsForApplicationGroupIdentifier:identifier];
        for (NSDictionary *dic in allEvents) {
            NSMutableDictionary *properties = [dic[@"properties"] mutableCopy];
            // 在采集的事件属性中加入预置属性
            [properties addEntriesFromDictionary:self.automaticProperties];

            NSMutableDictionary *event = [dic mutableCopy];
            event[@"properties"] = properties;

            // 将事件入库
            // [self.fileStore saveEvent:event];
            [self.database insertEvent:event];
        }
        // 将已经处理完成的数据删除
        [[SensorsAnalyticsExtensionDataManager sharedInstance] deleteAllEventsWithApplicationGroupIdentifier:identifier];

        // 将事件上传
        [self flush];
    });
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

#pragma mark - WebView
@implementation SensorsAnalyticsSDK (WebView)

- (void)loadUserAgent:(void(^)(NSString *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef SENSORS_ANALYTICS_UIWEBVIEW
        // 创建一个空的 webView
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        // 取出 webView 的 UserAgent
        NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        // 调用回调，返回获取到的 UserAgent
        completion(userAgent);
#else
        // 创建一个空的 webView，由于 WKWebView 执行 JavaScript 代码是异步过程，所以需要强引用 webView 对象
        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        // 创建一个 self 的弱引用，防止循环引用
        __weak typeof(self) weakSelf = self;
        // 执行 JavaScript 代码，获取 webView 中的 UserAgent
        [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
            // 创建强引用
            __strong typeof(weakSelf) strongSelf = weakSelf;
            // 调用回调，返回获取到的 UserAgent
            completion(result);
            // 释放 webView
            strongSelf.webView = nil;
        }];
#endif
    });
}

- (void)addWebViewUserAgent:(nullable NSString *)userAgent {
    [self loadUserAgent:^(NSString *oldUserAgent) {
        // 给 UserAgent 中添加自己需要的内容
        NSString *newUserAgent = [oldUserAgent stringByAppendingString:userAgent ?: @" /sa-sdk-ios "];
        // 将 UserAgent 字典内容注册到 NSUserDefaults 中
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": newUserAgent}];
    }];
}

- (void)trackFromH5WithEvent:(NSString *)jsonString {
    NSError *error = nil;
    // 将 json 字符串转换成 NSData 类型
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    // 解析 json
    NSMutableDictionary *event = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error || !event) {
        return;
    }

    NSMutableDictionary *properties = [event[@"properties"] mutableCopy];
    // 预置属性以 SDK 中采集的为主
    [properties addEntriesFromDictionary:self.automaticProperties];
    event[@"properties"] = properties;

    // 用于区分事件来源字段，表示是 H5 采集到的数据
    event[@"_hybrid_h5"] = @(YES);

    // 设置事件的 distinct_id，用于唯一标识一个用户
    event[@"distinct_id"] = self.loginId ?: self.anonymousId;

    // 打印最终的入库事件数据
    [self printEvent:event];

    // 本地保存事件数据
    // [self.fileStore saveEvent:event];
    [self.database insertEvent:event];

    // 在本地事件数据总量大于最大缓存数时，发送数据
    // if (self.fileStore.allEvents.count >= self.flushBulkSize) {
    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

- (BOOL)shouldTrackWithWebView:(id)webView request:(NSURLRequest *)request {
    // 获取请求的完整路径
    NSString *urlString = request.URL.absoluteString;
    // 查找在完整路径中是否包含：sensorsanalytics://trackEvent，如果不包含，那就是普通请求不做处理返回 NO
    if ([urlString rangeOfString:SensorsAnalyticsJavaScriptTrackEventScheme].location == NSNotFound) {
        return NO;
    }

    NSMutableDictionary *queryItems = [NSMutableDictionary dictionary];
    // 请求中的所有 Query，并解析获取数据
    NSArray<NSString *> *allQuery = [request.URL.query componentsSeparatedByString:@"&"];
    for (NSString *query in allQuery) {
        NSArray<NSString *> *items = [query componentsSeparatedByString:@"="];
        if (items.count >= 2) {
            queryItems[items.firstObject] = [items.lastObject stringByRemovingPercentEncoding];
        }
    }

    // TODO: 采集请求中的数据
    [self trackFromH5WithEvent:queryItems[@"event"]];

    return YES;
}

@end

#pragma mark - ReactNative
@implementation SensorsAnalyticsSDK (ReactNative)

/**
* 交换两个方法的实现
*
* @param className 需要交换的类名称
* @param methodName1 被交换的方法名，即原始的方法
* @param methodName2 交换后的方法名，即新的实现方法
* @param method2IMP 交换后的方法实现
*/
static inline void sensorsdata_method_exchange(const char *className, const char *methodName1, const char *methodName2, IMP method2IMP) {
    // 通过类名获取类
    Class cls = objc_getClass(className);
    // 获取原始方法的名
    SEL selector1 = sel_getUid(methodName1);
    // 通过方法名获取方法指针
    Method method1 = class_getInstanceMethod(cls, selector1);
    // 获得指定方法的描述
    struct objc_method_description *desc = method_getDescription(method1);
    if (desc->types) {
        // 把交换后的实现方法注册到 runtime 中
        SEL selector2 = sel_registerName(methodName2);
        // 通过运行时，把方法动态添加到类中
        if (class_addMethod(cls, selector2, method2IMP, desc->types)) {
            // 获取实例方法
            Method method2  = class_getInstanceMethod(cls, selector2);
            // 交换方法
            method_exchangeImplementations(method1, method2);
        }
    }
}

- (void)enableTrackReactNativeEvent {
    sensorsdata_method_exchange("RCTUIManager", "setJSResponder:blockNativeResponder:", "sensorsdata_setJSResponder:blockNativeResponder:", (IMP)sensorsdata_setJSResponder);
}

static void sensorsdata_setJSResponder(id obj, SEL cmd, NSNumber *reactTag, BOOL blockNativeResponder) {
    // 先执行原来的方法
    SEL oriSel = sel_getUid("sensorsdata_setJSResponder:blockNativeResponder:");
    // 获取原始方法的实现函数指针
    void (*imp)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))[obj methodForSelector:oriSel];
    // 完成第一步调用原始方法，让 React Native 完成事件响应
    imp(obj, cmd, reactTag, blockNativeResponder);

    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取 viewForReactTag: 的方法名，目的是获取触发当前触摸事件的控件
        SEL viewForReactTagSelector = NSSelectorFromString(@"viewForReactTag:");
        // 完成第二步，获取响应触摸事件的视图
        UIView *view = ((UIView * (*)(id, SEL, NSNumber *))[obj methodForSelector:viewForReactTagSelector])(obj, viewForReactTagSelector, reactTag);
        // 如果是 UIControl 的子类，例如：RCTSwitch、RCTSlider 等，直接返回
        // 如果是 RCTScrollView，说明是在滑动的响应，并不是控件的点击
        if ([view isKindOfClass:UIControl.class] || [view isKindOfClass:NSClassFromString(@"RCTScrollView")]) {
            return;
        }
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view properties:nil];
    });
}

@end
