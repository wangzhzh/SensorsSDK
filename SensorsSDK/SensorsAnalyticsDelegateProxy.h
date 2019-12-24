//
//  SensorsAnalyticsDelegateProxy.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDelegateProxy : NSProxy <UITableViewDelegate, UICollectionViewDelegate>

+ (instancetype)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

/**
 初始化委托对象，用于拦截 UICollectionView 的选中 cell 事件

 @param delegate UICollectionView 控件的代理
 @return 初始化对象
 */
+ (instancetype)proxyWithCollectionViewDelegate:(id<UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
