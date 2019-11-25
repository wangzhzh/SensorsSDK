//
//  NSObject+SASwizzler.h
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/11/18.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SASwizzler)

/**
交换方法名为 originalSEL 和方法名为 alternateSEL 两个方法的实现

@param originalSEL 原始方法名
@param alternateSEL 要交换的方法名称
*/
+ (BOOL)sensorsdata_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL;

@end

NS_ASSUME_NONNULL_END
