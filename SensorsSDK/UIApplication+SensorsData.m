//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/29.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIApplication+SensorsData.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

@implementation UIApplication (SensorsData)

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        swizzleMethod2([self class], @selector(sendAction:to:from:forEvent:), @selector(sensorsdata_sendAction:to:from:forEvent:));
//    });
//}

+ (void)swizzleUIApplication {
    Method originalMethod = class_getInstanceMethod([UIApplication class], @selector(sendAction:to:from:forEvent:));
    Method swizzledMethod = class_getInstanceMethod([self class], @selector(sensorsdata_sendAction:to:from:forEvent:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

void swizzleMethod2(Class class, SEL originalSelector, SEL swizzledSelector) {
    // 如果当前类没有实现这个方法，也会搜索父类
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // 如果方法已实现，则返回失败；如果方法没有实现，则返回成功
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


- (BOOL)sensorsdata_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent *)event {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    UIView *view = (UIView *)sender;
    
    //只统计触摸结束时
    if ([view isKindOfClass:[UISwitch class]] ||
        [view isKindOfClass:[UISegmentedControl class]] ||
        [view isKindOfClass:[UIStepper class]] ||
        [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
        //获取控件显示文本
        [properties setValue:view.sensorsDataElementContent forKey:@"$element_content"];
        
        //获取控件类型
        [properties setObject:NSStringFromClass([sender class]) forKey:@"$element_type"];
        
        //获取所属 UIViewController
        [properties setValue:NSStringFromClass([[view sensorsAnalyticsViewController] class]) forKey:@"screen_name"];
        
        //触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" andProperties:properties];
    }
    
    // 调用旧的实现，因为它们已经被替换了
    return [self sensorsdata_sendAction:action to:target from:sender forEvent:event];
}

@end
