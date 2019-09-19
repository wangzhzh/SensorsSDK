//
//  SensorsAnalyticsNetwork.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/9/8.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsNetwork : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// 数据上报的服务器地址
@property (nonatomic, strong) NSURL *serverURL;

/**
 指定初始化方法

 @param serverURL 服务器 URL 地址
 @return 初始化对象
 */
- (instancetype)initWithServerURL:(NSURL *)serverURL NS_DESIGNATED_INITIALIZER;

- (BOOL)flushEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END
