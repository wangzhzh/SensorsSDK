//
//  UITapGestureRecognizer+SensorsData.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/6/11.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITapGestureRecognizer (SensorsData)
+ (void)swizzleUITapGestureRecognizer;
@end

NS_ASSUME_NONNULL_END
