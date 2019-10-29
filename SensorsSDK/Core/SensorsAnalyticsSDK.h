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

#pragma mark - Flush
/// 当本地存储的事件达到这个数量时，上传数据（默认为 100）
@property (nonatomic) NSUInteger flushBulkSize;
/// 两次数据发送的时间间隔，单位秒
@property (nonatomic) NSUInteger flushInterval;

/**
 * @abstract
 * 获取 SDK 实例
 *
 * @return 返回单例
 */
+ (SensorsAnalyticsSDK * _Nullable)sharedInstance;



/**
 向服务器发送本地所有数据方法
 */
- (void)flush;

@end

@interface SensorsAnalyticsSDK (Track)

/**
 @abstract
 * 调用 track 接口，触发事件

 @discussion
 properties 是一个 NSDictionary。
 其中的 key 是 Property 的名称，必须是 NSString
 value 则是 Property 的内容

 @param eventName      事件名称
 @param properties     事件属性
 */
- (void)track:(NSString *)eventName properties:(nullable NSDictionary *)properties;

/**
 采集 H5 页面中的事件数据

 @param jsonString JS SDK 采集的事件数据
*/
- (void)trackFromH5WithEvent:(NSString *)jsonString;

/**
 通过 App Group Identifier 获取应用扩展中的事件数据，并先入库上传

 @param identifier App Group Identifier 
*/
- (void)trackFromAppExtensionForApplicationGroupIdentifier:(NSString *)identifier;

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

@interface SensorsAnalyticsSDK (WebView)

/**
在 WebView 中添加自定义的 UserAgent，这个接口用于实现打通方案

@param userAgent 自定义的 UserAgent
*/
- (void)addWebViewUserAgent:(nullable NSString *)userAgent;

/**
判断是否需要拦截并处理 JS SDK 发送过来的事件数据

@param webView 用于页面展示的 WebView 控件
@param request WebView 控件中的请求
*/
- (BOOL)shouldTrackWithWebView:(id)webView request:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
