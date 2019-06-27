//
//  SensorsAnalyticsSwizzle.h
//  SensorsSDK
//
//  Created by MC on 2019/6/22.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSwizzle : NSObject

/**
 将 sourceClass 的 sourceSelector 实例方法的实现与 destinationClass 的 destinationSelector 实例方法的实现进行交换
 该方法调用之后，[sourceClass sourceSelector] 相当于在此方法调用之前运行 [destinationClass destinationSelector]
 而 [aObject destinationSelector] 相当于在此方法调用之前运行 [aObject sourceSelector]

 @param sourceSelector 原方法名
 @param destinationSelector 需要替换原方法实现的方法名
 @return 若替换成功，返回 YES；若在该子类中不存在 sourceSelector 或者 destinationSelector 方法，就返回 NO
 */
//+ (void)swizzleInstanceMethodWithDestinationClass:(Class)destinationClass
//                              destinationSelector:(SEL)destinationSelector
//                                      sourceClass:(Class)sourceClass
//                                   sourceSelector:(SEL)sourceSelector;

@end

NS_ASSUME_NONNULL_END
