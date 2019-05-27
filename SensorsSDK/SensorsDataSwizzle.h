//
//  SensorsDataSwizzle.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SensorsDataSwizzle)
+ (BOOL)sensorsdata_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_;
+ (BOOL)sensorsdata_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError **)error_;
@end

NS_ASSUME_NONNULL_END
