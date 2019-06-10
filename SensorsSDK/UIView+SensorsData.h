//
//  UIView+SensorsData.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/30.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SensorsDataElementContent
@optional
- (NSString *)sensorsDataElementContent;
@end;

@interface UIView (SensorsData) <SensorsDataElementContent>
- (NSString *)sensorsDataElementContent;

- (nullable UIViewController *)sensorsAnalyticsViewController;
@end

@interface UIButton (SensorsData) <SensorsDataElementContent>
- (NSString *)sensorsDataElementContent;
@end

@interface UISwitch (SensorsData) <SensorsDataElementContent>
- (NSString *)sensorsDataElementContent;
@end

@interface UISlider (SensorsData) <SensorsDataElementContent>
- (NSString *)sensorsDataElementContent;
@end

NS_ASSUME_NONNULL_END
