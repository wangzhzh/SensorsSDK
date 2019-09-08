//
//  UIControl+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/9/5.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIControl+SensorsData.h"
#import "NSObject+SASwizzle.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SensorsData.h"

@implementation UIControl (SensorsData)

+ (void)load {
    [self sensorsdata_swizzleMethod:@selector(didMoveToSuperview) destinationSelector:@selector(sensorsdata_didMoveToSuperview)];
}

- (void)sensorsdata_didMoveToSuperview {
    // 调用交换前的原始方法实现
    [self sensorsdata_didMoveToSuperview];
    // 判断是否为一些特殊的控件
    if ([self isKindOfClass:UISwitch.class] || [self isKindOfClass:UISegmentedControl.class] || [self isKindOfClass:UIStepper.class] || [self isKindOfClass:UISlider.class]) {
        // 添加类型为 UIControlEventValueChanged 的一组 target-action
        [self addTarget:self action:@selector(sensorsdata_valueChangedAction:event:) forControlEvents:UIControlEventValueChanged];
    } else {
        // 添加类型为 UIControlEventTouchDown 的一组 target-action
        [self addTarget:self action:@selector(sensorsdata_touchDownAction:event:) forControlEvents:UIControlEventTouchDown];
    }
}

- (void)sensorsdata_valueChangedAction:(UIControl *)sender event:(UIEvent *)event {
    if ([self isKindOfClass:UISlider.class] && [[[event allTouches] anyObject] phase] != UITouchPhaseEnded) {
        return;
    }
    // 获取所有的 target 数量
    NSUInteger targetCount = self.allTargets.count;
    // 获取 target 为 self 的 UIControlEventValueChanged 的 actions
    NSArray<NSString *> *executeEventActions = [self actionsForTarget:self forControlEvent:UIControlEventValueChanged];
    // 当控件中添加的 target-action 多于两组时，表示在 SDK 外已添加了 target-action，因此我们直接调用触发埋点的方法
    if (targetCount >= 2 || executeEventActions.count >= 2) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender];
    }
}

- (void)sensorsdata_touchDownAction:(UIControl *)sender event:(UIEvent *)event {
    // 获取所有的 target 数量
    NSUInteger targetCount = self.allTargets.count;
    // 获取 target 为 self 的 UIControlEventValueChanged 的 actions
    NSArray<NSString *> *executeEventActions = [self actionsForTarget:self forControlEvent:UIControlEventValueChanged];
    // 当控件中添加的 target-action 多于两组时，表示在 SDK 外已添加了 target-action，因此我们直接调用触发埋点的方法
    if (targetCount >= 2 || executeEventActions.count >= 2) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender];
    }
}

@end
