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
#import "SensorsAnalyticsNetwork.h"
#import "SensorsAnalyticsExtensionDatsManager.h"
#import "NSObject+SASwizzle.h"

#include <objc/runtime.h>

#ifndef SENSORS_ANALYTICS_DISENABLE_WKWEBVIEW
#import <WebKit/WebKit.h>
#endif

#define VERSION @"1.0.0"

static NSString *SensorsAnalyticsEventBeginKey = @"event_begin";
static NSString *SensorsAnalyticsEventDurationKey = @"event_duration";
static NSString *SensorsAnalyticsEventIsPauseKey = @"is_pause";
static NSString *SensorsAnalyticsEventDidEnterBackgroundKey = @"did_enter_background";

static NSUInteger SensorsAnalyticsDefalutFlushEventCount = 50;

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

/// 数据上传等网络请求对象
@property (nonatomic, strong) SensorsAnalyticsNetwork *network;
/// 定时器
@property (nonatomic, strong) NSTimer *flushTimer;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

#ifndef SENSORS_ANALYTICS_DISENABLE_WKWEBVIEW
// 由于 WKWebView 获取 UserAgent 是异步过程，为了在获取过程中创建的 WKWebView 对象不被销毁，需要保存创建的临时对象
@property (nonatomic, strong) WKWebView *webView;
#endif

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
        _flushBulkSize = 100;
        _flushInterval = 15;
        [self startFlushTimer];

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

        _network = [[SensorsAnalyticsNetwork alloc] initWithServerURL:[NSURL URLWithString:@"www.baidu.com"]];

        NSString *queueLabel = [NSString stringWithFormat:@"cn.sensorsdata.%@.%p", self.class, self];
        _serialQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);

    }
    return self;
}

- (void)sensorsdata_execute:(UIControl *)sender {
//    NSLog(@"Function: %s, Sender: %@, Event: %@", __FUNCTION__, sender, event);
    NSLog(@"-----");
}

#pragma mark - Appliction
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

//    if (_appRelaunched) {
        [self track:@"$AppStart" properties:nil];
//    }

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
}

#pragma mark - React Native


#pragma mark - Timer
/// 开启上传数据的定时器
- (void)startFlushTimer {
    // 当时间间隔设置小于5秒时，设置间隔为5秒
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    // 初始化计时器
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    // 将计时器添加到 RunLoop 中，开启定时器
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}
// 停止上传数据的定时器
- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
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
        NSTimeInterval time = UIApplication.sharedApplication.backgroundTimeRemaining;
        // 当 app 进入前台运行时，backgroundTimeRemaining 会返回 DBL_MAX
        // 当运行时间小于请求的超时时间时，为保证数据库删除时不被应用强杀，不再继续上传
        if (time == DBL_MAX || time <= 30.5) {
            return;
        }
    }

    // 获取本地数据
    NSArray<NSString *> *events = [self.database selectEventsForCount:count];
    // 当本地存储的数据为 0 或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || [self.network flushEvents:events]) {
        return;
    }
    // 当删除数据失败时，直接返回退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }

    // 继续上传本地的其他数据
    [self flushByEventCount:count background:background];
}

#pragma mark - Property
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

@end

#pragma mark - Track
@implementation SensorsAnalyticsSDK (Track)

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
//        [self.fileStore saveEvent:eventProperties];
        [self.database insertEvent:eventProperties];
    }

    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
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
    // 添加一些 JS SDK 中较难获取到的信息，例如 Wi-Fi 信息
    // 开发者可以自行添加一些其他的事件属性
    // event[@"$wifi"] = @(YES);

    // 用于区分事件来源字段，表示是 H5 采集到的数据
    event[@"_hybrid_h5"] = @(YES);

    // 移除一些无用的 key
    [event removeObjectForKey:@"_nocache"];
    [event removeObjectForKey:@"server_url"];

    // 打印最终的入库事件数据
    NSLog(@"[Event]: %@", event);

    // 本地保存事件数据
    // [self.fileStore saveEvent:event];
    [self.database insertEvent:event];

    // 在本地事件数据总量大于最大缓存数时，发送数据
    // if (self.fileStore.allEvents.count >= self.flushBulkSize) {
    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

- (void)trackFromAppExtensionForApplicationGroupIdentifier:(NSString *)identifier {
    dispatch_async(self.serialQueue, ^{
        // 获取 App Group Identifier 对应的应用扩展中采集的事件数据
        NSArray *allEvents = [[SensorsAnalyticsExtensionDatsManager sharedInstance] allEventsForApplicationGroupIdentifier:identifier];
        if (allEvents.count == 0) {
            return;
        }
        for (NSDictionary *dic in allEvents) {
            NSMutableDictionary *properties = [dic[@"properties"] mutableCopy];
            // 在采集的事件属性中加入预置属性
            [properties addEntriesFromDictionary:self.automaticProperties];

            NSMutableDictionary *event = [dic mutableCopy];
            event[@"properties"] = properties;
            NSLog(@"[Event]: %@", event);

            // 将事件入库
            // [self.fileStore saveEvent:event];
            [self.database insertEvent:event];
        }
        // 将已经处理完成的数据删除
        [[SensorsAnalyticsExtensionDatsManager sharedInstance] deleteAllEventsWithApplicationGroupIdentifier:identifier];
        // 将事件上传
        [self flush];
    });
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

@implementation SensorsAnalyticsSDK (WebView)

- (void)loadUserAgent:(void(^)(NSString *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef SENSORS_ANALYTICS_DISENABLE_WKWEBVIEW
        // 创建一个空的 webView
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        // 取出 webView 的 UserAgent
        NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        // 调用回调，返回获取到的 UserAgent
        completion(userAgent);
#else
        // 创建一个空的 webView，由于 WKWebView 执行 Javascript 代码是异步过程，所以需要强引用 webView 对象
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
        NSString *newUserAgent = [oldUserAgent stringByAppendingString:userAgent ?: @" /sa-sdk-ios"];
        // 将 UserAgent 字典内容注册到 NSUserDefaults 中
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": newUserAgent}];
    }];
}

static NSString * const SensorsAnalyticsJavascriptTrackEventScheme = @"sensorsanalytics://trackEvent";

- (BOOL)shouldTrackWithWebView:(id)webView request:(NSURLRequest *)request {
    if (!webView) {
        return NO;
    }
    // 获取请求的完整路径
    NSString *urlString = request.URL.absoluteString;
    // 查找在完整路径中是否包含：sensorsanalytics://trackEvent，如果不包含，那就是普通请求不做处理返回 NO
    if ([urlString rangeOfString:SensorsAnalyticsJavascriptTrackEventScheme].location == NSNotFound) {
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

    [self trackFromH5WithEvent:queryItems[@"event"]];

    return YES;
}

@end

@implementation SensorsAnalyticsSDK (ReactNative)

/**
* 交换两个方法的实现
*
* @param className 需要交换的方法名称
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
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view];
    });
}

@end
