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

@property (nonatomic, weak) id<UITableViewDelegate> delegate;

@end

@implementation SensorsAnalyticsDelegateProxy

+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

- (void)dealloc {
    _delegate = nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [(NSObject *)self.delegate methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.delegate];
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        invocation.selector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
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
