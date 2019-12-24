//
//  UIGestureRecognizer+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UIGestureRecognizer+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"

#pragma mark - UITapGestureRecognizer
@implementation UITapGestureRecognizer (SensorsData)

+ (void)load {
    // Swizzle initWithTarget:action: 方法
    [UITapGestureRecognizer sensorsdata_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(sensorsdata_initWithTarget:action:)];
    // Swizzle addTarget:action: 方法
    [UITapGestureRecognizer sensorsdata_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(sensorsdata_addTarget:action:)];
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self sensorsdata_initWithTarget:target action:action];
    // 调用添加 Target-Action 方法，添加埋点的 Target-Action
    // 这里其实调用的是 sensorsdata_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // 调用原始的方法，添加 Target-Action
    [self sensorsdata_addTarget:target action:action];
    // 新增 Target-Action，用于埋点
    [self sensorsdata_addTarget:self action:@selector(sensorsdata_trackTapGestureAction:)];
}

- (void)sensorsdata_trackTapGestureAction:(UITapGestureRecognizer *)sender {
    // 获取手势识别器的控件
    UIView *view = sender.view;
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }

    // $AppClick 事件的属性，这里只需要设置 $element_type，其他的事件属性在 trackAppClickWithView:properties: 中可自动获取
    NSDictionary *properties = @{@"$element_type": NSStringFromClass(self.class)};
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view properties:properties];
}

@end

#pragma mark - UILongPressGestureRecognizer
@implementation UILongPressGestureRecognizer (SensorsData)

+ (void)load {
    // Swizzle initWithTarget:action: 方法
    [UILongPressGestureRecognizer sensorsdata_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(sensorsdata_initWithTarget:action:)];
    // Swizzle addTarget:action: 方法
    [UILongPressGestureRecognizer sensorsdata_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(sensorsdata_addTarget:action:)];
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self sensorsdata_initWithTarget:target action:action];
    // 调用添加 Target-Action 方法，添加埋点的 Target-Action
    // 这里其实调用的是 sensorsdata_addTarget:action: 里的实现方法，因为已经进行了 swizzle
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // 调用原始的方法，添加 Target-Action
    [self sensorsdata_addTarget:target action:action];
    // 新增 Target-Action，用于埋点
    [self sensorsdata_addTarget:self action:@selector(sensorsdata_trackLongPressGestureAction:)];
}

- (void)sensorsdata_trackLongPressGestureAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }
    // 获取手势识别器的控件
    UIView *view = sender.view;
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }

    // $AppClick 事件的属性，这里只需要设置 $element_type，其他的事件属性在 trackAppClickWithView:properties: 中可自动获取
    NSDictionary *properties = @{@"$element_type": NSStringFromClass(self.class)};
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view properties:properties];
}

@end
