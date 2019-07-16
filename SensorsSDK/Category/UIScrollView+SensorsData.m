//
//  UIScrollView+SensorsData.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/7/16.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIScrollView+SensorsData.h"
#include <objc/runtime.h>

@implementation UIScrollView (SensorsData)

- (void)setSensorsdata_delegateProxy:(SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, @selector(setSensorsdata_delegateProxy:), sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN);
}

- (SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, @selector(sensorsdata_delegateProxy));
}

@end
