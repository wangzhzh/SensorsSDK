//
//  SensorsAnalyticsExceptionHandler.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/6/9.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsExceptionHandler : NSObject
+ (instancetype)sharedHandler;
- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance;
@end

NS_ASSUME_NONNULL_END
