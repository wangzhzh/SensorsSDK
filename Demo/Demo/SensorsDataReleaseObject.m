//
//  SensorsDataReleaseObject.m
//  demo
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
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
