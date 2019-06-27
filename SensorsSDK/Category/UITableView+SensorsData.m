//
//  UITableView+SensorsData.m
//  SensorsSDK
//
//  Created by MC on 2019/6/21.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UITableView+SensorsData.h"
#import "NSObject+SASwizzle.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsDelegateProxy.h"
#include <objc/runtime.h>
#include <objc/message.h>

#pragma mark - NSObject+UITableView_DidSelectRow

//@interface NSObject (UITableView_DidSelectRow)
//
//- (void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
//
//@end
//
//@implementation NSObject (UITableView_DidSelectRow)
//
//- (void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self sensorsdata_tableView:tableView didSelectRowAtIndexPath:indexPath];
//
//    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
//    // 获取控件显示文本
//    properties[@"$element_content"] = tableView.sensorsdata_elementContent;
//
//    // 获取控件类型
//    properties[@"$element_type"] = NSStringFromClass([tableView class]);
//
//    // 获取所属 UIViewController
//    properties[@"screen_name"] = NSStringFromClass([tableView.sensorsdata_viewController class]);
//
//    // 触发 $AppClick 事件
//    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
//}
//
//@end

static void sensorsdata_tableViewDidSelectRow(id object, SEL selector, UITableView *tableView, NSIndexPath *indexPath) {
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
    // 通过消息发送，调用原始的 tableView:didSelectRowAtIndexPath: 方法实现
    ((void(*)(id, SEL, id, id))objc_msgSend)(object, destinationSelector, tableView, indexPath);

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // 获取控件显示文本
    properties[@"$element_content"] = tableView.sensorsdata_elementContent;

    // 获取控件类型
    properties[@"$element_type"] = NSStringFromClass([tableView class]);

    // 获取所属 UIViewController
    properties[@"screen_name"] = NSStringFromClass([tableView.sensorsdata_viewController class]);

    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

#pragma mark - UITableView+SensorsData

@implementation UITableView (SensorsData)

+ (void)swizzleUITableView {
    [UITableView sensorsdata_swizzleMethod:@selector(setDelegate:) destinationSelector:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate:(id<UITableViewDelegate>)delegate {
    // 通过 Swizzle 之后，此处相当于调用 [self setDelegate:delegate]
    [self sensorsdata_setDelegate:delegate];

    // 方案一：方法交换
//    [self sensorsdata_swizzleDidSelectRowMethodWithDelegate:delegate];

    // 方案二：动态子类
    [SensorsAnalyticsDelegateProxy proxyWithTableViewDelegate:delegate];
}

- (void)sensorsdata_swizzleDidSelectRowMethodWithDelegate:(id<UITableViewDelegate>)delegate {
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

    Method sourceMethod = class_getInstanceMethod([delegate class], sourceSelector);
    const char * encoding = method_getTypeEncoding(sourceMethod);
    // 当该类中已经存在了相同的方法时，会失败。但是前面已经判断过是否存在，因此，此处一定会添加成功。
    if (!class_addMethod([delegate class], destinationSelector, (IMP)sensorsdata_tableViewDidSelectRow, encoding)) {
        NSLog(@"Add %@ to %@ error", NSStringFromSelector(sourceSelector), [delegate class]);
        return;
    }

    Method destinationMethod = class_getInstanceMethod([delegate class], destinationSelector);
    method_exchangeImplementations(sourceMethod, destinationMethod);
}

@end


