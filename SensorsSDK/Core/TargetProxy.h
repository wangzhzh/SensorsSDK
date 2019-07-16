//
//  TargetProxy.h
//  SensorsSDK
//
//  Created by MC on 2019/7/4.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TargetProxy : NSProxy

- (instancetype)initWithObject1:(id)object1 object2:(id)object2;

@end

NS_ASSUME_NONNULL_END
