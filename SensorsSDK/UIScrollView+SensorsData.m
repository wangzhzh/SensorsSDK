//
//  UIScrollView+SensorsData.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "UIScrollView+SensorsData.h"
#include <objc/runtime.h>

@implementation UIScrollView (SensorsData)

- (void)setSensorsdata_delegateProxy:(SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, @selector(setSensorsdata_delegateProxy:), sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, @selector(sensorsdata_delegateProxy));
}

@end
