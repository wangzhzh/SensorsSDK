//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/18.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"

static NSString * const kSensorsDataBlackListFileName = @"sensorsdata_black_list";

@implementation UIViewController (SensorsData)

+ (void)load {
    [UIViewController sensorsdata_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_viewDidAppear:)];
}

- (BOOL)shouldTrackAppViewScreen {
    static NSSet *blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 获取黑名单文件路径
        NSString *path = [[NSBundle bundleForClass:SensorsAnalyticsSDK.class] pathForResource:kSensorsDataBlackListFileName ofType:@"plist"];
        // 读取文件中黑名单类名的数组
        NSArray *classNames = [NSArray arrayWithContentsOfFile:path];
        NSMutableSet *set = [NSMutableSet setWithCapacity:classNames.count];
        for (NSString *className in classNames) {
            [set addObject:NSClassFromString(className)];
        }
        blackList = [set copy];
    });
    for (Class cla in blackList) {
        // 判断当前视图控制器是否为黑名单中的类或子类
        if ([self isKindOfClass:cla]) {
            return NO;
        }
    }
    return YES;
}

- (void)sensorsdata_viewDidAppear:(BOOL)animated {
    // 调用原始方法，即 viewDidAppear:
    [self sensorsdata_viewDidAppear:animated];

    if ([self shouldTrackAppViewScreen]) {
        // 触发 $AppViewScreen
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppViewScreen" properties:@{@"$screen_name": NSStringFromClass([self class])}];
    }
}

@end
