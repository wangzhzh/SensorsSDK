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

///**
//* 交换两个方法的实现
//*
//* @param className 需要交换的方法名称
//* @param methodName1 被交换的方法名，即原始的方法
//* @param methodName2 交换后的方法名，即新的实现方法
//* @param method2IMP 交换后的方法实现
//*/
//static inline void sensorsdata_method_exchange(const char *className, const char *methodName1, const char *methodName2, IMP method2IMP) {
//    // 通过类名获取类
//    Class cls = objc_getClass(className);
//    // 获取原始方法的名
//    SEL selector1 = sel_getUid(methodName1);
//    // 通过方法名获取方法指针
//    Method method1 = class_getInstanceMethod(cls, selector1);
//    // 获得指定方法的描述
//    struct objc_method_description *desc = method_getDescription(method1);
//    if (desc->types) {
//        // 把交换后的实现方法注册到 runtime 中
//        SEL selector2 = sel_registerName(methodName2);
//        // 通过运行时，把方法动态添加到类中
//        if (class_addMethod(cls, selector2, method2IMP, desc->types)) {
//            // 获取实例方法
//            Method method2  = class_getInstanceMethod(cls, selector2);
//            // 交换方法
//            method_exchangeImplementations(method1, method2);
//        }
//    }
//}

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
