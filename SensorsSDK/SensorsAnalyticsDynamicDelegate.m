//
//  SensorsAnalyticsDynamicDelegate.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/21.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsDynamicDelegate.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

/// Delegate 的子类前缀
static NSString *const kSensorsDelegatePrefix = @"cn.SensorsData.";
// tableView:didSelectRowAtIndexPath: 方法指针类型
typedef void (*SensorsDidSelectImplementation)(id, SEL, UITableView *, NSIndexPath *);

@implementation SensorsAnalyticsDynamicDelegate

+ (void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    // 当 delegate 中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:originalSelector]) {
        return;
    }

    // 动态创建一个新类
    Class originalClass = object_getClass(delegate);
    NSString *originalClassName = NSStringFromClass(originalClass);
    // 当这个 delegate 对象已经是一个动态创建的类时，无需重复设置，直接返回
    if ([originalClassName hasPrefix:kSensorsDelegatePrefix]) {
        return;
    }

    NSString *subclassName = [kSensorsDelegatePrefix stringByAppendingString:originalClassName];
    Class subclass = NSClassFromString(subclassName);
    if (!subclass) {
        // 注册一个新的子类，其父类为 originalClass
        subclass = objc_allocateClassPair(originalClass, subclassName.UTF8String, 0);

        // 获取 SensorsAnalyticsDynamicDelegate 中的 tableView:didSelectRowAtIndexPath: 方法指针
        Method method = class_getInstanceMethod(self, originalSelector);
        // 获取方法的实现
        IMP methodIMP = method_getImplementation(method);
        // 获取方法的类型编码
        const char *types = method_getTypeEncoding(method);
        // 在 subclass 中添加 tableView:didSelectRowAtIndexPath: 方法
        if (!class_addMethod(subclass, originalSelector, methodIMP, types)) {
            NSLog(@"Cannot copy method to destination selector %@ as it already exists", NSStringFromSelector(originalSelector));
        }

        // 获取 SensorsAnalyticsDynamicDelegate 中的 sensorsdata_class 方法指针
        Method classMethod = class_getInstanceMethod(self, @selector(sensorsdata_class));
        // 获取方法的实现
        IMP classIMP = method_getImplementation(classMethod);
        // 获取方法的类型编码
        const char *classTypes = method_getTypeEncoding(classMethod);
        // 在 subclass 中添加 class 方法
        if (!class_addMethod(subclass, @selector(class), classIMP, classTypes)) {
            NSLog(@"Cannot copy method to destination selector -(void)class as it already exists");
        }

        // 子类和原始类的大小必须相同，不能有更多的 ivars 或者属性
        // 如果不同会导致设置新的子类时，会重新设置内存，导致重写了对象的 isa 指针
        if (class_getInstanceSize(originalClass) != class_getInstanceSize(subclass)) {
            NSLog(@"Cannot create subclass of Delegate, because the created subclass is not the same size. %@", NSStringFromClass(originalClass));
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return;
        }

        // 将 delegate 对象设置成新创建的子类对象
        objc_registerClassPair(subclass);
    }

    if (object_setClass(delegate, subclass)) {
        NSLog(@"Successfully created Delegate Proxy automatically.");
    }
}

- (Class)sensorsdata_class {
    // 获取对象的类
    Class class = object_getClass(self);
    // 将类名前缀替换成空字符串，获取原始类名
    NSString *className = [NSStringFromClass(class) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    // 通过字符串获取类，并返回
    return objc_getClass([className UTF8String]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 第一步：获取原始类
    Class cla = object_getClass(tableView.delegate);
    NSString *className = [NSStringFromClass(cla) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    Class originalClass = objc_getClass([className UTF8String]);

    // 第二步：调用开发者自己实现的方法
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP originalImplementation = method_getImplementation(originalMethod);
    if (originalImplementation) {
        ((SensorsDidSelectImplementation)originalImplementation)(tableView.delegate, originalSelector, tableView, indexPath);
    }

    // 第三步：埋点
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

@end
