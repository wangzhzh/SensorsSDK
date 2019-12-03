//
//  SensorsAnalyticsKeychainPasswordItem.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/12/3.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsKeychainPasswordItem : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithService:(NSString *)service account:(NSString *)account;
- (instancetype)initWithService:(NSString *)service account:(NSString *)account accessGroup:(nullable NSString *)accessGroup NS_DESIGNATED_INITIALIZER;

- (nullable NSString *)readPassword;
- (void)savePassword:(NSString *)password;
- (void)renameAccount:(NSString *)account;
- (void)deleteItem;

@end

NS_ASSUME_NONNULL_END
