//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/20.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UIApplication+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"
#import "UIView+SensorsData.h"

@implementation UIApplication (SensorsData)

//+ (void)load {
//    [UIApplication sensorsdata_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(sensorsdata_sendAction:to:from:forEvent:)];
//}

- (BOOL)sensorsdata_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent *)event {
    if ([sender isKindOfClass:UISwitch.class] ||
        [sender isKindOfClass:UISegmentedControl.class] ||
        [sender isKindOfClass:UIStepper.class] ||
        event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }

    // 调用旧的实现，因为它们已经被替换了
    return [self sensorsdata_sendAction:action to:target from:sender forEvent:event];
}

@end
