//
//  UIScrollView+DelegateProxy.m
//  SensorsSDK
//
//  Created by MC on 2019/7/8.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "UIScrollView+DelegateProxy.h"
#include <objc/runtime.h>

@implementation UIScrollView (DelegateProxy)

- (void)setSensorsdata_delegateProxy:(SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, @selector(setSensorsdata_delegateProxy:), sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN);
}

- (SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, @selector(sensorsdata_delegateProxy));
}

@end
