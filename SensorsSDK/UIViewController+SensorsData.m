//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/5/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIViewController+SensorsData.h"
#import "SensorsAnalyticsSDK.h"

@implementation UIViewController (SensorsData)

- (void)sensorsdata_viewDidAppear:(BOOL)animated {
    [[SensorsAnalyticsSDK sharedInstance] track:@"AppViewScreen" andProperties:nil];
    [self sensorsdata_viewDidAppear:animated];
}

@end
