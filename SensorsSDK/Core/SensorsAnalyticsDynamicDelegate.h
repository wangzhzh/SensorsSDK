//
//  SensorsAnalyticsDelegateProxy.h
//  SensorsSDK
//
//  Created by MC on 2019/6/26.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDynamicDelegate : NSObject

+ (void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
