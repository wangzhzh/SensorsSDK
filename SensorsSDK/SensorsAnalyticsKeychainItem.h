//
//  SensorsAnalyticsKeychainItem.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/12/3.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsKeychainItem : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithService:(NSString *)service key:(NSString *)key;
- (instancetype)initWithService:(NSString *)service accessGroup:(nullable NSString *)accessGroup key:(NSString *)key NS_DESIGNATED_INITIALIZER;

- (nullable NSString *)value;
- (void)update:(NSString *)value;
- (void)remove;

@end

NS_ASSUME_NONNULL_END
