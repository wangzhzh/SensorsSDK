//
//  UICollectionView+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/21.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UICollectionView+SensorsData.h"
#import "SensorsAnalyticsDelegateProxy.h"
#import "UIScrollView+SensorsData.h"
#import "NSObject+SASwizzler.h"

@implementation UICollectionView (SensorsData)

+ (void)load {
    [UICollectionView sensorsdata_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate:(id<UICollectionViewDelegate>)delegate {
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy proxyWithCollectionViewDelegate:delegate];
    self.sensorsdata_delegateProxy = proxy;
    [self sensorsdata_setDelegate:proxy];
}


@end
