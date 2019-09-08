//
//  SensorsAnalyticsFileStore.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/8/20.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsFileStore : NSObject

@property (nonatomic, copy, readonly) NSString *filePath;

/// 本地最大缓存事件数量
@property (nonatomic) NSUInteger maxLocalEventCount;

@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *allEvents;

/**
 将事件持久化保存到文件中

 @param event 事件数据
 */
- (void)saveEvent:(NSDictionary *)event;

- (void)deleteEventsForCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
