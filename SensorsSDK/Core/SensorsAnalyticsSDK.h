//
//  SensorsAnalyticsSDK.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK : NSObject

/**
 * @abstract
 * 获取 SDK 实例
 *
 * @return 返回单例
 */
+ (SensorsAnalyticsSDK * _Nullable)sharedInstance;

/**
 * @abstract
 * 调用 track 接口，触发事件
 *
 * @discussion
 * properties 是一个 NSDictionary。
 * 其中的 key 是 Property 的名称，必须是 NSString
 * value 则是 Property 的内容
 *
 * @param eventName      事件名称
 * @param properties     事件属性
 */
- (void)track:(NSString *)eventName properties:(nullable NSDictionary *)properties;

- (void)trackTimerStart:(NSString *)event;

- (void)trackTimerEnd:(NSString *)event properties:(nullable NSDictionary *)properties;

/**
 采集 UITableView 的 $AppClick 事件

 @param tableView UITableView 控件对象
 @param indexPath 点击选中的 NSIndexPath 对象
 */
- (void)trackTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 采集 UICollectionView 的 $AppClick 事件

 @param collectionView UICollectionView 控件对象
 @param indexPath 点击选中的 NSIndexPath 对象
 */
- (void)trackCollectionView:(UICollectionView *)collectionView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END