//
//  SensorsAnalyticsDelegateProxy.h
//  SensorsSDK
//
//  Created by MC on 2019/6/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDelegateProxy : NSProxy <UITableViewDelegate>

/**
 初始化方法，通过 delegate 对象创建一个委托对象

 @param delegate 代理
 @return 初始化对象
 */
+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
