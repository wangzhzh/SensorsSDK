//
//  UIScrollView+SensorsData.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/21.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorsAnalyticsDelegateProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (SensorsData)

@property (nonatomic, strong) SensorsAnalyticsDelegateProxy *sensorsdata_delegateProxy;

@end

NS_ASSUME_NONNULL_END
