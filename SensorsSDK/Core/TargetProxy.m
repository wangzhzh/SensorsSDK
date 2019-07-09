//
//  TargetProxy.m
//  SensorsSDK
//
//  Created by MC on 2019/7/4.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "TargetProxy.h"

@implementation TargetProxy {
    // 保存需要将消息转发到的第一个真实对象
    // 这个对象的方法调用优先级会比第二个高
    id _realObject1;
    // 保存需要将消息转发到的第二个真实对象
    id _realObject2;
}


/**
 初始化方法
 保存两个真实对象

 @param object1 第一个真实对象
 @param object2 第二个真实对象
 @return 初始化对象
 */
- (instancetype)initWithObject1:(id)object1 object2:(id)object2 {
    _realObject1 = object1;
    _realObject2 = object2;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // 获取 _realObject1 中 aSelector 的方法签名
    NSMethodSignature *signature = [_realObject1 methodSignatureForSelector:aSelector];
    // 如果在 _realObject1 中有该方法，那么就返回此方法的签名
    // 如果没有再查看 _realObject2
    if (signature) {
        return signature;
    }
    // 获取 _realObject2 中 aSelector 的方法签名
    signature = [_realObject2 methodSignatureForSelector:aSelector];
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 获取拥有该方法的真实对象
    id target = [_realObject1 methodSignatureForSelector:[invocation selector]] ? _realObject1 : _realObject2;
    // 执行方法
    [invocation invokeWithTarget:target];
}

@end
