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

#pragma mark - NSObject+UITableView_DidSelectRow

@interface NSObject (DidSelecteAtIndexPath)

- (void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation NSObject (DidSelecteAtIndexPath)

- (void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self sensorsdata_tableView:tableView didSelectRowAtIndexPath:indexPath];

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // 获取控件显示文本
    properties[@"$element_content"] = tableView.sensorsdata_elementContent;

    // 获取控件类型
    properties[@"$element_type"] = tableView.sensorsdata_elementType;

    // 获取所属 UIViewController
    properties[@"screen_name"] = NSStringFromClass([tableView.sensorsdata_viewController class]);

    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

@end

@implementation UITableView (SensorsData)

+ (void)load {
    [UITableView sensorsdata_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate:(id<UITableViewDelegate>)delegate {
    // 方案一：方法交换
    // 调用原始的设置代理的方法
//    [self sensorsdata_setDelegate:delegate];
    // 交换 delegate 中的 tableView:didSelectRowAtIndexPath: 方法
//    [delegate.class sensorsdata_swizzleMethod:@selector(tableView:didSelectRowAtIndexPath:) withMethod:@selector(sensorsdata_tableView:didSelectRowAtIndexPath:)];

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

@end
