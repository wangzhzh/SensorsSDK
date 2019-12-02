//
//  SensorsAnalyticsSDK.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/6.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK : NSObject

/// 当本地存储的事件达到这个数量时，上传数据（默认为 100）
@property (nonatomic) NSUInteger flushBulkSize;
/// 两次数据发送的时间间隔，单位秒
@property (nonatomic) NSUInteger flushInterval;

@property (nonatomic, copy, readonly) NSString *loginId;

@property (nonatomic, copy) NSString *anonymousId;

- (instancetype)init NS_UNAVAILABLE;

/**
@abstract
获取 SDK 实例

@return 返回单例
*/
+ (SensorsAnalyticsSDK *)sharedInstance;

/**
初始化 SDK
*/
+ (void)startWithServerURL:(NSURL *)url;

/**
用户登录，设置登录 ID

@param loginId 用户的登录 ID
*/
- (void)login:(NSString *)loginId;

/**
 向服务器发送本地所有数据方法
 */
- (void)flush;

@end

#pragma mark - Track
@interface SensorsAnalyticsSDK (Track)

/**
@abstract
调用 track 接口，触发事件

@discussion
properties 是一个 NSDictionary。
其中的 key 是 Property 的名称，必须是 NSString
value 则是 Property 的内容

@param eventName      事件名称
@param properties     事件属性
*/
- (void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *, id> *)properties;

/**
让视图触发 $AppClick 事件

@param view 触发事件的视图
@param properties 自定义事件属性
*/
- (void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *, id> *)properties;

/**
支持 UITableView 触发 $AppClick 事件

@param tableView 触发事件的 UITableView 视图
@param indexPath 在 UITableView 中点击的位置
@param properties 自定义事件属性
*/
- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties;

/**
支持 UICollectionView 触发 $AppClick 事件

@param collectionView 触发事件的 UICollectionView 视图
@param indexPath 在 UICollectionView 中点击的位置
@param properties 自定义事件属性
*/
- (void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties;

/**
 通过 App Group Identifier 获取应用扩展中的事件数据，并先入库上传

 @param identifier App Group Identifier
*/
- (void)trackFromAppExtensionForApplicationGroupIdentifier:(NSString *)identifier;

@end

#pragma mark - Timer
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

#pragma mark - WebView
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

/**
 采集 H5 页面中的事件数据

@param jsonString JS SDK 采集的事件数据
*/
- (void)trackFromH5WithEvent:(NSString *)jsonString;

@end

#pragma mark - ReactNative
@interface SensorsAnalyticsSDK (ReactNative)

- (void)enableTrackReactNativeEvent;

@end

NS_ASSUME_NONNULL_END
