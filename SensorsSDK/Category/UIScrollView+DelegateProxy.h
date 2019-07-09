//
//  UIScrollView+DelegateProxy.h
//  SensorsSDK
//
//  Created by MC on 2019/7/8.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorsAnalyticsDelegateProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (DelegateProxy)

@property (nonatomic, strong) SensorsAnalyticsDelegateProxy *sensorsdata_delegateProxy;

@end

NS_ASSUME_NONNULL_END
