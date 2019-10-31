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
    // 如果是隐藏控件，则不获取控件内容
    if (self.isHidden) {
        return nil;
    }
    // 初始化数组，用于保存子控件的内容
    NSMutableArray *contents = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        // 获取子控件的内容
        // 如果子类有内容，例如：UILabel 的 text，获取到的就是 text 属性；
        // 如果没有就递归调用此方法，获取其子控件的内容。
        NSString *content = view.sensorsdata_elementContent;
        if (content.length > 0) {
            // 当该子控件中有内容时，保存在数组中
            [contents addObject:content];
        }
    }
    // 当未获取到子控件内容时返回 accessibilityLabel。如果获取到多个子控件内容时，使用 - 拼接
    return contents.count == 0 ? self.accessibilityLabel : [contents componentsJoinedByString:@"-"];
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
    return self.currentTitle ?: super.sensorsdata_elementContent;
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
    return self.text ?: super.sensorsdata_elementContent;
}

@end
