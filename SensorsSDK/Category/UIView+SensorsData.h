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
/// 获取控件的内容
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;
@end;

@interface UIView (SensorsData) <SensorsDataElementContent>

@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;

/// 获取 view 所在的 viewController，或者当前的 viewController
@property (nonatomic, readonly) UIViewController *sensorsdata_viewController;

@end

#pragma mark - Element
@interface UIButton (SensorsData) <SensorsDataElementContent>

@end

@interface UISwitch (SensorsData) <SensorsDataElementContent>

@end

@interface UISlider (SensorsData) <SensorsDataElementContent>

@end

@interface UISegmentedControl (SensorsData) <SensorsDataElementContent>

@end

@interface UIStepper (SensorsData) <SensorsDataElementContent>

@end

@interface UILabel (SensorsData) <SensorsDataElementContent>

@end

NS_ASSUME_NONNULL_END
