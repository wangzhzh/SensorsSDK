//
//  UITableView+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/21.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UITableView+SensorsData.h"
#import "SensorsAnalyticsDynamicDelegate.h"
#import "SensorsAnalyticsDelegateProxy.h"
#import "NSObject+SASwizzler.h"
#import "UIScrollView+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SensorsData.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - NSObject+UITableView_DidSelectRow

@implementation UITableView (SensorsData)

+ (void)load {
    [UITableView sensorsdata_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate:(id<UITableViewDelegate>)delegate {
    // 方案一：方法交换
    // 调用原始的设置代理的方法
//    [self sensorsdata_setDelegate:delegate];
    // 交换 delegate 中的 tableView:didSelectRowAtIndexPath: 方法
//    [self sensorsdata_swizzleDidSelectRowAtIndexPathMethodWithDelegate:delegate];

    // 方案二：动态子类
    // 调用原始的设置代理的方法
//    [self sensorsdata_setDelegate:delegate];
    // 设置 delegate 的动态子类
//    [SensorsAnalyticsDynamicDelegate proxyWithTableViewDelegate:delegate];

    // 方案三：NSProxy 消息转发
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy proxyWithTableViewDelegate:delegate];
    // 保存委托对象
    self.sensorsdata_delegateProxy = proxy;
    // 将 delegate 设置成委托类
    [self sensorsdata_setDelegate:proxy];
}

static void sensorsdata_tableViewDidSelectRow(id object, SEL selector, UITableView *tableView, NSIndexPath *indexPath) {
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
    // 通过消息发送，调用原始的 tableView:didSelectRowAtIndexPath: 方法实现
    ((void(*)(id, SEL, id, id))objc_msgSend)(object, destinationSelector, tableView, indexPath);

    // TODO: 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

- (void)sensorsdata_swizzleDidSelectRowAtIndexPathMethodWithDelegate:(id)delegate {
    // 获取 delegate 的类
    Class delegateClass = [delegate class];
    // 方法名
    SEL sourceSelector = @selector(tableView:didSelectRowAtIndexPath:);
    // 当 delegate 中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }

    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
    // 当 delegate 中已经存在了 sensorsdata_tableView:didSelectRowAtIndexPath: 方法，那就说明已经进行过 swizzle 了，因此就可以直接返回，不再进行 swizzle
    if ([delegate respondsToSelector:destinationSelector]) {
        return;
    }

    Method sourceMethod = class_getInstanceMethod(delegateClass, sourceSelector);
    const char * encoding = method_getTypeEncoding(sourceMethod);
    // 当该类中已经存在了相同的方法时，会失败。但是前面已经判断过是否存在，因此，此处一定会添加成功。
    if (!class_addMethod([delegate class], destinationSelector, (IMP)sensorsdata_tableViewDidSelectRow, encoding)) {
        NSLog(@"Add %@ to %@ error", NSStringFromSelector(sourceSelector), [delegate class]);
        return;
    }
    // 添加成功之后，进行方法交换
    [delegateClass sensorsdata_swizzleMethod:sourceSelector withMethod:destinationSelector];
}

@end
