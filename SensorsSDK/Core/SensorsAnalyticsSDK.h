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

@end

@interface SensorsAnalyticsSDK (AppClick)

- (void)trackAppClickWithView:(UIView *)view;


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

@interface SensorsAnalyticsSDK (Timer)

/**
 开始统计事件时长

 调用这个接口时，并不会真正触发一次事件

 @param event 事件名
 */
- (void)trackTimerStart:(NSString *)event;

/**
 暂停统计事件时长

 如果该事件未开始，即没有调用 trackTimerStart: 方法，则不做任何操作

 @param event 事件名
 */
- (void)trackTimerPause:(NSString *)event;

/**
 恢复统计事件时长

 如果该事件并未暂停，即没有调用 trackTimerPause: 方法，则没有影响

 @param event 事件名
 */
- (void)trackTimerResume:(NSString *)event;

/**
 结束事件时长统计，计算时长

 事件发生时长是从调用 trackTimerStart: 开始计算，到调用 trackTimerEnd:properties: 的时间。
 如果多次调用 trackTimerStart: 从最后一次调用开始计算。
 如果没有调用 trackTimerStart: 直接调用 trackTimerEnd:properties: 则触发一次普通事件，不会带时长属性

 @param event 事件名，与 start 时事件名一一对应
 @param properties 事件属性
 */
- (void)trackTimerEnd:(NSString *)event properties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
