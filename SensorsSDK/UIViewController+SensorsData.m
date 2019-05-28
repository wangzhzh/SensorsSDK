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

- (void)sensorsdata_viewDidAppear:(BOOL)animated
{
    // call original implementation
    [self sensorsdata_viewDidAppear:animated];
    
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppViewScreen" andProperties:@{@"$screen_name": NSStringFromClass([self class])}];
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector)
{
    // the method might not exist in the class, but in its superclass
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // class_addMethod will fail if original method already exists
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    // the method doesn’t exist and we just added one
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

@end
