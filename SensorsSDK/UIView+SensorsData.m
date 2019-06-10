//
//  UIView+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/30.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIView+SensorsData.h"

@implementation UIView (SensorsData)

- (NSString *)sensorsDataElementContent {
    return nil;
}

- (UIViewController *)sensorsAnalyticsViewController {
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

- (NSString *)sensorsDataElementContent {
    NSString *elementContent = self.currentAttributedTitle.string;
    if (elementContent != nil && elementContent.length > 0) {
        return elementContent;
    }
    return self.currentTitle;
}

@end

@implementation UISwitch (SensorsData)
- (NSString *)sensorsDataElementContent {
    if (self.isOn) {
        return @"checked";
    } else {
        return @"unchecked";
    }
}
@end

@implementation UISlider (SensorsData)
- (NSString *)sensorsDataElementContent {
    return [NSString stringWithFormat:@"%.2f",self.value];
}
@end
