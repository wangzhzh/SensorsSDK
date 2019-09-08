//
//  SensorsAnalyticsDatabase.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/8/28.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDatabase : NSObject

/// 数据库文件路径
@property (nonatomic, copy, readonly) NSString *filePath;

/**
 初始化方法

 @param filePath 数据库路径，如果为 nil 则使用默认路径
 @return 数据库对象
 */
- (instancetype)initWithFilePath:(nullable NSString *)filePath NS_DESIGNATED_INITIALIZER;

/**
 同步向数据库中插入事件

 @param event 事件
 */
- (void)insertEvent:(NSDictionary *)event;

/**
 从数据库中获取事件数据

 @param count 获取事件数据的条数
 @return 事件数据
 */
- (NSArray<NSString *> *)selectEventsForCount:(NSUInteger)count;

/**
 从数据库中删除一定数量的事件数据

 @param count 需要删除的事件数量
 */
- (void)deleteEventsForCount:(NSUInteger)count;


@end

NS_ASSUME_NONNULL_END