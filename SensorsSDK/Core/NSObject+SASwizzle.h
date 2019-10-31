//
//  NSObject+SASwizzle.h
//  SensorsSDK
//
//  Created by MC on 2019/6/22.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//static void sensorsdata_method_exchange(const char *className, const char *methodName1, const char *methodName2, IMP method2IMP);

@interface NSObject (SASwizzle)

/**
 将 NSObject 子类中的 sourceSelector 方法的实现替换为 destinationSelector 方法的实现
 该方法调用之后，[aObject sourceSelector] 相当于在此方法调用之前运行 [aObject destinationSelector]
 而 [aObject destinationSelector] 相当于在此方法调用之前运行 [aObject sourceSelector]

 @param sourceSelector 原方法名
 @param destinationSelector 需要替换原方法实现的方法名
 @return 若替换成功，返回 YES；若在该子类中不存在 sourceSelector 或者 destinationSelector 方法，就返回 NO
 */
+ (BOOL)sensorsdata_swizzleMethod:(SEL)sourceSelector destinationSelector:(SEL)destinationSelector;

@end

NS_ASSUME_NONNULL_END
