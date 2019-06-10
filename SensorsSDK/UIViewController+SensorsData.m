//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

@implementation UIViewController (SensorsData)

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        swizzleMethod([self class], @selector(viewDidAppear:), @selector(sensorsdata_viewDidAppear:));
//    });
//}

+ (void)swizzleUIViewController {
    Method originalMethod = class_getInstanceMethod([UIViewController class], @selector(viewDidAppear:));
    Method swizzledMethod = class_getInstanceMethod([self class], @selector(sensorsdata_viewDidAppear:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)sensorsdata_viewDidAppear:(BOOL)animated {
    // 调用旧的实现，因为它们已经被替换了
    [self sensorsdata_viewDidAppear:animated];
    
    // track $AppViewScreen 事件
    if ([self shouldTrackAppViewScreen:self.class]) {
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
        //navigationItem.titleView 的优先级高于 navigationItem.title
        NSString *title = [self contentFromView:self.navigationItem.titleView];
        if (!title) {
            title = self.navigationItem.title;
        }
        [properties setValue:title forKey:@"$title"];
        
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppViewScreen" andProperties:properties];
    }
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    // 如果当前类没有实现这个方法，也会搜索父类
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // 如果方法已实现，则返回失败；如果方法没有实现，则返回成功
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (BOOL)shouldTrackAppViewScreen:(Class)aClass {
    static NSSet *classesBlacklist = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *classNamesBlacklist = @[ @"UINavigationController", @"UIInputWindowController"];
        NSMutableSet *classesTransformed = [NSMutableSet setWithCapacity:classNamesBlacklist.count];
        for (NSString *className in classNamesBlacklist) {
            [classesTransformed addObject:NSClassFromString(className)];
        }
        classesBlacklist = [classesTransformed copy];
    });
    
    return ![classesBlacklist containsObject:aClass];
}

- (NSString *)contentFromView:(UIView *)rootView {
    if (rootView.isHidden) {
        return nil;
    }
    
    NSMutableString *elementContent = [NSMutableString string];
    
    if ([rootView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)rootView;
        NSString *title = button.currentAttributedTitle.string;
        if (title != nil && title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[rootView class]]) {
        UILabel *label = (UILabel *)rootView;
        NSString *title = label.attributedText.string;
        if (title != nil && title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)rootView;
        NSString *title = textView.attributedText.string;
        if (title != nil && title.length > 0) {
            [elementContent appendString:title];
        }
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        
        for (UIView *subview in rootView.subviews) {
            NSString *temp = [self contentFromView:subview];
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }
    
    return [elementContent copy];
}

@end
