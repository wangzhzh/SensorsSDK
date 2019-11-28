//
//  SensorsDataReleaseObject.m
//  demo
//
//  Created by 张敏超🍎 on 2019/8/12.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsDataReleaseObject.h"

@implementation SensorsDataReleaseObject

- (void)signalCrash {
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] init];
    [array addObject:@"First"];
    [array release];
    // 在这里会崩溃，因为 array 已经被释放了，访问了不存在的地址
    NSLog(@"Crash: %@", array.firstObject);
}

@end
