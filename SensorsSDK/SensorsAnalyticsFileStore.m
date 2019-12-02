//
//  SensorsAnalyticsFileStore.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/25.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsFileStore.h"

static NSString * const SensorsAnalyticsDefaultFileName = @"SensorsAnalyticsData.plist";

@interface SensorsAnalyticsFileStore ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *events;

/// 保存一个先进先出的队列
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SensorsAnalyticsFileStore

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化默认事件数据存储地址
         _filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultFileName];

        // 初始化队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"cn.sensorsdata.serialQueue.%p", self];
        // 创建一个 serial 类型的 queue，即 FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);

        // 从文件路径中读取数据
        [self readAllEventsFromFilePath:_filePath];

        // 初始化本地最大缓存事件数量
        _maxLocalEventCount = 10000;
    }
    return self;
}

- (NSArray<NSDictionary *> *)allEvents {
    __block NSArray<NSDictionary *> *allEvents = nil;
    dispatch_sync(self.queue, ^{
        allEvents = [self.events copy];
    });
    return allEvents;
}

- (void)saveEvent:(NSDictionary *)event {
    dispatch_async(self.queue, ^{
        // 当当前事件数据超过最大值时，需要移除之前的老数据
        if (self.events.count >= self.maxLocalEventCount) {
            [self.events removeObjectAtIndex:0];
        }
        // 在数组中直接添加事件数据
        [self.events addObject:event];
        // 将事件数据保存在文件中
        [self writeEventsToFile];
    });
}

- (void)readAllEventsFromFilePath:(NSString *)filePath {
    dispatch_async(self.queue, ^{
        // 从文件路径中读取数据
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            // 解析在文件中读取的 json 数据
            NSMutableArray *allEvents = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            // 将文件中的数据保存在内存中
            self.events = allEvents ?: [NSMutableArray array];
        } else {
            self.events = [NSMutableArray array];
        }
    });
}

- (void)writeEventsToFile {
    // json 解析错误信息
    NSError *error = nil;
    // 将字典数据解析成 json data
    NSData *data = [NSJSONSerialization dataWithJSONObject:_events options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"The json object's serialization error: %@", error);
    }
    // 将数据写入文件中
    [data writeToFile:self.filePath atomically:YES];
}

- (void)deleteEventsForCount:(NSInteger)count {
    dispatch_async(self.queue, ^{
        // 删除前 count 条事件数据
        [self.events removeObjectsInRange:NSMakeRange(0, count)];
        // 将删除后剩余的事件数据保存到文件中
        [self writeEventsToFile];
    });
}

@end
