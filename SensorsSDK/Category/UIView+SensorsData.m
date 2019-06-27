//
//  UIView+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/30.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIView+SensorsData.h"

@implementation UIView (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return nil;
}

- (UIViewController *)sensorsdata_viewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])){
        if ([responder isKindOfClass: [UIViewController class]]){
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到则返回 nil
    return nil;
}

@end

@implementation UIButton (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return self.currentTitle;
}

@end

@implementation UISwitch (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UISlider (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%.2f",self.value];
}

@end

@implementation UISegmentedControl (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIStepper (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UILabel (SensorsData)

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end
