//
//  UITapGestureRecognizer+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/6/11.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UITapGestureRecognizer+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SensorsData.h"
#import <objc/runtime.h>

@implementation UITapGestureRecognizer (SensorsData)

+ (void)swizzleUITapGestureRecognizer {
//    Method originalMethod = class_getInstanceMethod([UITapGestureRecognizer class], @selector(addTarget:action:));
//    Method swizzledMethod = class_getInstanceMethod([self class], @selector(sensorsdata2_addTarget:action:));
//    method_exchangeImplementations(originalMethod, swizzledMethod);
//
//    Method originalMethod2 = class_getInstanceMethod([UITapGestureRecognizer class], @selector(initWithTarget:action:));
//    Method swizzledMethod2 = class_getInstanceMethod([self class], @selector(sensorsdata2_initWithTarget:action:));
//    method_exchangeImplementations(originalMethod2, swizzledMethod2);
}

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    // 暂定只采集 UILabel 和 UIImageView
    BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
    if (!isTrackClass) {
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    //获取控件显示文本
    [properties setValue:view.sensorsDataElementContent forKey:@"$element_content"];
    
    //获取控件类型
    [properties setObject:NSStringFromClass([gesture.view class]) forKey:@"$element_type"];
    
    //获取所属 UIViewController
    [properties setValue:NSStringFromClass([[view sensorsAnalyticsViewController] class]) forKey:@"screen_name"];
    
    //触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:properties];
}

- (instancetype)sensorsdata2_initWithTarget:(id)target action:(SEL)action {
    [self sensorsdata2_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata2_addTarget:(id)target action:(SEL)action {
    [self sensorsdata2_addTarget:target action:action];
    [self sensorsdata2_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
}

@end
