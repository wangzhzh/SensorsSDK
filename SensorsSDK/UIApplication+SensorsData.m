//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/29.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIApplication+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

@implementation UIApplication (SensorsData)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleMethod2([self class], @selector(sendAction:to:from:forEvent:), @selector(sensorsdata_sendAction:to:from:forEvent:));
    });
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
    //触发 $AppClick 事件
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" andProperties:nil];
    
    // 调用旧的实现，因为它们已经被替换了
    return [self sensorsdata_sendAction:action to:target from:sender forEvent:event];
}

@end
