//
//  NSObject+SASwizzler.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/18.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "NSObject+SASwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (SASwizzler)

+ (BOOL)sensorsdata_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL {
    // 获取原始方法
    Method originalMethod = class_getInstanceMethod(self, originalSEL);
    // 当原始方法不存在时，返回 NO，表示 Swizzling 失败
    if (!originalMethod) {
        return NO;
    }

    // 获取要交换的方法
    Method alternateMethod = class_getInstanceMethod(self, alternateSEL);
    // 当要交换的方法不存在时，返回 NO，表示 Swizzling 失败
    if (!alternateMethod) {
        return NO;
    }

    // 获取 originalSEL 方法的实现
    IMP originalIMP = method_getImplementation(originalMethod);
    // 获取 originalSEL 方法的类型
    const char * originalMethodType = method_getTypeEncoding(originalMethod);
    // 往类中添加 originalSEL 方法，如果已经存在会添加失败，并返回 NO
    if (class_addMethod(self, originalSEL, originalIMP, originalMethodType)) {
        // 如果添加成功了，重新获取 originalSEL 实例方法
        originalMethod = class_getInstanceMethod(self, originalSEL);
    }

    // 获取 alternateIMP 方法的实现
    IMP alternateIMP = method_getImplementation(alternateMethod);
    // 获取 alternateIMP 方法的类型
    const char * alternateMethodType = method_getTypeEncoding(alternateMethod);
    // 往类中添加 alternateIMP 方法，如果已经存在会添加失败，并返回 NO
    if (class_addMethod(self, alternateSEL, alternateIMP, alternateMethodType)) {
        // 如果添加成功了，重新获取 alternateIMP 实例方法
        alternateMethod = class_getInstanceMethod(self, alternateSEL);
    }

    // 交换两个方法的实现
    method_exchangeImplementations(originalMethod, alternateMethod);

    // 返回 YES，表示 Swizzling 成功
    return YES;
}

@end
