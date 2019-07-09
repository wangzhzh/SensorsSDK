//
//  SensorsAnalyticsDelegateProxy.m
//  SensorsSDK
//
//  Created by MC on 2019/7/1.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsAnalyticsDelegateProxy.h"
#import "UIView+SensorsData.h"
#import "SensorsAnalyticsSDK.h"

@interface SensorsAnalyticsDelegateProxy ()

/// 保存 delegate 对象
@property (nonatomic, weak) id<UITableViewDelegate> delegate;

@end

@implementation SensorsAnalyticsDelegateProxy

+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    // 返回 delegate 对象中对应的方法签名
    return [(NSObject *)self.delegate methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 先执行 delegate 对象中的方法
    [invocation invokeWithTarget:self.delegate];
    // 判断是否是 cell 的点击事件的代理方法
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        // 将方法名修改为进行数据采集的方法，即本类中的实例方法：sensorsdata_tableView:didSelectRowAtIndexPath:
        invocation.selector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
        // 执行数据采集相关的方法
        [invocation invokeWithTarget:self];
    }
}

- (void)sensorsdata_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 第三步：埋点
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

@end
