//
//  UIView+SensorsData.h
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SensorsDataElementProperty
@protocol SensorsDataElementProperty

/// 控件的类型
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementType;

/// 获取控件的内容
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;

@end

#pragma mark - UIView
@interface UIView (SensorsData) <SensorsDataElementProperty>

@property (nonatomic, copy, readonly) NSString *sensorsdata_elementType;

@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;

/// 获取 view 所在的 viewController，或者当前的 viewController
@property (nonatomic, readonly) UIViewController *sensorsdata_viewController;

@end

#pragma mark - UILabel
@interface UILabel (SensorsData)

@end

#pragma mark - UIButton
@interface UIButton (SensorsData)

@end

#pragma mark - UISwitch
@interface UISwitch (SensorsData)

@end

#pragma mark - UISlider
@interface UISlider (SensorsData)

@end

#pragma mark - UISegmentedControl
@interface UISegmentedControl (SensorsData)

@end

#pragma mark - UIStepper
@interface UIStepper (SensorsData)

@end

NS_ASSUME_NONNULL_END
