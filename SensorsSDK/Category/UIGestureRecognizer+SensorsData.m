//
//  UIGestureRecognizer+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/7/31.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIGestureRecognizer+SensorsData.h"
#import "NSObject+SASwizzle.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsSDK.h"

@implementation UITapGestureRecognizer (SensorsData)

+ (void)load {
    // Swizzle initWithTarget:action: 方法
    [self sensorsdata_swizzleMethod:@selector(initWithTarget:action:) destinationSelector:@selector(sensorsdata_initWithTarget:action:)];
    // Swizzle addTarget:action: 方法
    [self sensorsdata_swizzleMethod:@selector(addTarget:action:) destinationSelector:@selector(sensorsdata_addTarget:action:)];
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self sensorsdata_initWithTarget:target action:action];
    // 调用添加 target-action 方法，添加埋点的 target-action 对
    // 这里其实调用的是 sensorsdata_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // 调用原始的方法，添加 target-action 对
    [self sensorsdata_addTarget:target action:action];
    // 新增 target-action 对，用于埋点
    [self sensorsdata_addTarget:self action:@selector(trackTapGestureAction:)];
}

- (void)trackTapGestureAction:(UITapGestureRecognizer *)sender {
    // 获取手势识别器的控件
    UIView *view = sender.view;
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    // 获取控件显示文本
    properties[@"$element_content"] = view.sensorsdata_elementContent;

    // 获取控件类型
    properties[@"$element_type"] = NSStringFromClass([sender class]);

    // 获取所属 UIViewController
    properties[@"screen_name"] = NSStringFromClass([view.sensorsdata_viewController class]);

    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

@end


@implementation UILongPressGestureRecognizer (SensorsData)

+ (void)load {
    // Swizzle initWithTarget:action: 方法
    [self sensorsdata_swizzleMethod:@selector(initWithTarget:action:) destinationSelector:@selector(sensorsdata_initWithTarget:action:)];
    // Swizzle addTarget:action: 方法
    [self sensorsdata_swizzleMethod:@selector(addTarget:action:) destinationSelector:@selector(sensorsdata_addTarget:action:)];
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self sensorsdata_initWithTarget:target action:action];
    // 调用添加 target-action 方法，添加埋点的 target-action 对
    // 这里其实调用的是 sensorsdata_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // 调用原始的方法，添加 target-action 对
    [self sensorsdata_addTarget:target action:action];
    // 新增 target-action 对，用于埋点
    [self sensorsdata_addTarget:self action:@selector(trackLongGestureAction:)];
}

- (void)trackLongGestureAction:(UILongPressGestureRecognizer *)sender {
    // 获取手势识别器的控件
    UIView *view = sender.view;
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    // 获取控件显示文本
    properties[@"$element_content"] = view.sensorsdata_elementContent;

    // 获取控件类型
    properties[@"$element_type"] = NSStringFromClass([sender class]);

    // 获取所属 UIViewController
    properties[@"screen_name"] = NSStringFromClass([view.sensorsdata_viewController class]);

    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

@end
