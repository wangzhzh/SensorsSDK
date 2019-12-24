//
//  SensorsAnalyticsExtensionDatsManager.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsExtensionDataManager.h"

static NSString * const kSensorsExtensionFileName = @"sensors_analytics_extension_events.plist";

@implementation SensorsAnalyticsExtensionDataManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SensorsAnalyticsExtensionDataManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SensorsAnalyticsExtensionDataManager alloc] init];
    });
    return manager;
}

- (NSURL *)fileURLForApplicationGroupIdentifier:(NSString *)identifier {
    return [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:identifier] URLByAppendingPathComponent:kSensorsExtensionFileName];
}

/**
把所有的事件数据写入文件中保存

@param events 所有的事件数据
@param url 事件数据写入文件地址
*/
- (void)writeEvents:(NSArray<NSDictionary *> *)events toURL:(NSURL *)url {
    // json 解析错误信息
    NSError *error = nil;
    // 将字典数据解析成 json data
    NSData *data = [NSJSONSerialization dataWithJSONObject:events options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"The json object's serialization error: %@", error);
    }
    // 将数据写入文件中
    [data writeToURL:url atomically:YES];
}

/**
从一个路径中获取所有的事件数据

@param url 获取所有事件数据的文件地址
@return 所有的事件数据
*/
- (NSMutableArray<NSDictionary *> *)allEventsForURL:(NSURL *)url {
    // 从文件中初始化 NSData 对象
    NSData *data = [NSData dataWithContentsOfURL:url];
    // 当本地未保存事件数据时，直接返回空数组
    if (data.length == 0) {
        return [NSMutableArray array];
    }
    // 解析所有的 JSON 数据
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary<NSString *,id> *)properties applicationGroupIdentifier:(NSString *)identifier {
    // 当事件名和事件属性都为空时，说明事件数据有问题，直接返回
    // 当 App Group Identifier 为空时，表示获取不到共享资源文件地址，直接返回
    if ((event.length == 0 && properties.count == 0) || identifier.length == 0) {
        return;
    }

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    // 设置事件名称
    dictionary[@"event"] = event;
    // 设置当前事件触发的时间
    NSNumber *timeStamp = @([[NSDate date] timeIntervalSince1970] * 1000);
    dictionary[@"time"] = timeStamp;
    // 设置事件属性
    dictionary[@"properties"] = properties;

    // 根据 App Group Identifier 获取事件保存的文件地址
    NSURL *url = [self fileURLForApplicationGroupIdentifier:identifier];

    // 获取本地存储的所有事件数据
    NSMutableArray *events = [self allEventsForURL:url];
    // 添加事件数据
    [events addObject:dictionary];

    // 将数据写入文件中进行保存
    [self writeEvents:events toURL:url];
}

- (NSMutableArray<NSDictionary *> *)allEventsForApplicationGroupIdentifier:(NSString *)identifier {
    // 根据 App Group Identifier 获取事件保存的文件地址
    NSURL *url = [self fileURLForApplicationGroupIdentifier:identifier];
    // 读取保存的所有的事件
    return [self allEventsForURL:url];
}

- (void)deleteAllEventsWithApplicationGroupIdentifier:(NSString *)identifier {
    // 根据 App Group Identifier 获取事件保存的文件地址
    NSURL *url = [self fileURLForApplicationGroupIdentifier:identifier];
    // 将空数组写入文件中保存
    [self writeEvents:@[] toURL:url];
}

@end
