//
//  UIControl+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UIControl+SensorsData.h"
#import "NSObject+SASwizzler.h"
#import "SensorsAnalyticsSDK.h"

@implementation UIControl (SensorsData)

+ (void)load {
    [UIControl sensorsdata_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(sensorsdata_didMoveToSuperview)];
}

- (void)sensorsdata_didMoveToSuperview {
    // 调用交换前的原始方法实现
    [self sensorsdata_didMoveToSuperview];
    // 判断是否为一些特殊的控件
    if ([self isKindOfClass:UISwitch.class] ||
        [self isKindOfClass:UISegmentedControl.class] ||
        [self isKindOfClass:UIStepper.class] ||
        [self isKindOfClass:UISlider.class]
        ) {
        // 添加类型为 UIControlEventValueChanged 的一组 Target-Action
        [self addTarget:self action:@selector(sensorsdata_valueChangedAction:event:) forControlEvents:UIControlEventValueChanged];
    } else {
        // 添加类型为 UIControlEventTouchDown 的一组 Target-Action
        [self addTarget:self action:@selector(sensorsdata_touchDownAction:event:) forControlEvents:UIControlEventTouchDown];
    }
}

- (BOOL)sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent:(UIControlEvents)defaultControlEvent {
    // 如果有多个 Target 说明除了我们添加的 Target 对象还有其他
    // 那么返回 YES 触发 $AppClick 事件
    if (self.allTargets.count >= 2) {
        return YES;
    }
    // 如果控件本身为 Target 对象，并且添加除了 UIControlEventTouchDown 类型的 Action 方法
    // 说明开发者以本身为 Target 对象，添加了多个 Action 方法
    // 那么返回 YES 触发 $AppClick 事件
    if ((self.allControlEvents & UIControlEventAllTouchEvents) != defaultControlEvent) {
        return YES;
    }
    // 如果控件本身为 Target 对象，并添加了两个以上的 UIControlEventTouchDown 类型的 Action 方法
    // 那说明开发者自行添加了 Actions 方法
    // 所以返回 YES 触发 $AppClick 事件
    if ([self actionsForTarget:self forControlEvent:defaultControlEvent].count >= 2) {
        return YES;
    }
    return NO;
}

- (void)sensorsdata_valueChangedAction:(UIControl *)sender event:(UIEvent *)event {
    if ([sender isKindOfClass:UISlider.class] && event.allTouches.anyObject.phase != UITouchPhaseEnded) {
        return;
    }
    if ([self sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent:UIControlEventValueChanged]) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
}

- (void)sensorsdata_touchDownAction:(UIControl *)sender event:(UIEvent *)event {
    if ([self sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent:UIControlEventTouchDown]) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
}

@end
