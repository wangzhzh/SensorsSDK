//
//  NSObject+SASwizzle.m
//  SensorsSDK
//
//  Created by MC on 2019/6/22.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "NSObject+SASwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "TargetProxy.h"

@implementation NSObject (SASwizzle)

+ (BOOL)sensorsdata_swizzleMethod:(SEL)sourceSelector destinationSelector:(SEL)destinationSelector {
    Method sourceMethod = class_getInstanceMethod(self, sourceSelector);
    if (!sourceMethod) {
        return NO;
    }

    Method destinationMethod = class_getInstanceMethod(self, destinationSelector);
    if (!destinationMethod) {
        return NO;
    }

    class_addMethod(self, sourceSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod));
    class_addMethod(self, destinationSelector, method_getImplementation(destinationMethod), method_getTypeEncoding(destinationMethod));

    method_exchangeImplementations(class_getInstanceMethod(self, sourceSelector), class_getInstanceMethod(self, destinationSelector));
    return YES;
}

@end
