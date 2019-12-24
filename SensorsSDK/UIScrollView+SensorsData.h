//
//  UIScrollView+SensorsData.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorsAnalyticsDelegateProxy.h"

@interface UIScrollView (SensorsData)

@property (nonatomic, strong) SensorsAnalyticsDelegateProxy *sensorsdata_delegateProxy;

@end
