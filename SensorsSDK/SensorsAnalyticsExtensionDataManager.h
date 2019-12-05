//
//  SensorsAnalyticsExtensionDataManager.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/25.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsExtensionDataManager : NSObject

+ (instancetype)sharedInstance;

/**
根据 App Group Identifier 获取文件地址

@param identifier App Group Identifier
@return 路径地址
*/
- (NSURL *)fileURLForApplicationGroupIdentifier:(NSString *)identifier;

/**
触发事件，采集事件名及相关属性

@param event 事件名
@param properties 事件属性
@param identifier App Group Identifier
*/
- (void)track:(NSString *)event properties:(NSDictionary<NSString *,id> *)properties applicationGroupIdentifier:(NSString *)identifier;

/**
根据 App Group Identifier 获取保存的所有事件数据

@param identifier App Group Identifier
@return 路径地址
*/
- (NSArray<NSDictionary *> *)allEventsForApplicationGroupIdentifier:(NSString *)identifier;

/**
根据 App Group Identifier 删除保存的所有事件数据

@param identifier App Group Identifier
*/
- (void)deleteAllEventsWithApplicationGroupIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
