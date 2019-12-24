//
//  SensorsAnalyticsFileStore.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsFileStore : NSObject

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *allEvents;

/// 本地最大缓存事件数量
@property (nonatomic) NSUInteger maxLocalEventCount;

/**
 将事件持久化保存到文件中

 @param event 事件数据
 */
- (void)saveEvent:(NSDictionary *)event;

/**
f根据数量删除本地保存的事件数据

@param count 需要删除的事件数量
*/
- (void)deleteEventsForCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
