//
//  UICollectionView+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/7/16.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UICollectionView+SensorsData.h"
#import "NSObject+SASwizzle.h"
#import "SensorsAnalyticsDelegateProxy.h"
#import "UIScrollView+SensorsData.h"

@implementation UICollectionView (SensorsData)

+ (void)swizzleCollectionView {
    [UICollectionView sensorsdata_swizzleMethod:@selector(setDelegate:) destinationSelector:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate:(id<UICollectionViewDelegate>)delegate {
    // 方案一：方法交换
    // 通过 Swizzle 之后，此处相当于调用 [self setDelegate:delegate]
    [self sensorsdata_setDelegate:delegate];
//    [self sensorsdata_swizzleDidSelectRowMethodWithDelegate:delegate];

    // 方案二：动态子类
//    [self sensorsdata_setDelegate:delegate];
//    [SensorsAnalyticsDynamicDelegate proxyWithTableViewDelegate:delegate];

    // 方案三：NSProxy 消息转发
//    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy proxyWithCollectionViewDelegate:delegate];
//    self.sensorsdata_delegateProxy = proxy;
//    [self sensorsdata_setDelegate:proxy];
}

@end
