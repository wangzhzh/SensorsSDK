//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

@implementation UIViewController (SensorsData)

+ (void)load {
    swizzleMethod([self class], @selector(viewDidAppear:), @selector(sensorsdata_viewDidAppear:));
}

- (void)sensorsdata_viewDidAppear:(BOOL)animated {
    // 调用旧的实现，因为它们已经被替换了
    [self sensorsdata_viewDidAppear:animated];
    
    // track $AppViewScreen
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppViewScreen" andProperties:@{@"$screen_name": NSStringFromClass([self class])}];
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
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

@end
