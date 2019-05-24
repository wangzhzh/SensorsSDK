//
//  SensorsAnalyticsSDK.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK : NSObject

+ (SensorsAnalyticsSDK * _Nullable)sharedInstance;

- (void)track:(NSString *)eventName andProperties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
