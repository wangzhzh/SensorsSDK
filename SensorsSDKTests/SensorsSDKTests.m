//
//  SensorsSDKTests.m
//  SensorsSDKTests
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface SensorsSDKTests : XCTestCase

@end

@implementation SensorsSDKTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceArchiver {
    // This is an example of a performance test case.
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 200; i++) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSInteger i = 0; i < 200; i++) {
            dic[[NSString stringWithFormat:@"key%ld", i]] = [NSString stringWithFormat:@"value%ld", i];
        }
        [array addObject:dic];
    }

    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"archiver.plist"];
    [self measureBlock:^{
        [NSKeyedArchiver archiveRootObject:array toFile:filePath];
    }];
}

- (void)testPerformanceUnarchiver {
    // This is an example of a performance test case.
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 200; i++) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSInteger i = 0; i < 200; i++) {
            dic[[NSString stringWithFormat:@"key%ld", i]] = [NSString stringWithFormat:@"value%ld", i];
        }
        [array addObject:dic];
    }

    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"archiver.plist"];
    [self measureBlock:^{
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//        NSLog(@"%@", array);
    }];
}

- (void)testPerformanceWriteJSON {
    // This is an example of a performance test case.
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 200; i++) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSInteger i = 0; i < 200; i++) {
            dic[[NSString stringWithFormat:@"key%ld", i]] = [NSString stringWithFormat:@"value%ld", i];
        }
        [array addObject:dic];
    }

    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"json.plist"];
    [self measureBlock:^{
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"json.plist"] atomically:YES];
    }];
}

- (void)testPerformanceReadJSON {
    // This is an example of a performance test case.
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 200; i++) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSInteger i = 0; i < 200; i++) {
            dic[[NSString stringWithFormat:@"key%ld", i]] = [NSString stringWithFormat:@"value%ld", i];
        }
        [array addObject:dic];
    }

    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"json.plist"];
    [self measureBlock:^{
        NSData *data2 = [NSData dataWithContentsOfFile:filePath];
        NSArray *array = [NSJSONSerialization JSONObjectWithData:data2 options:NSJSONReadingAllowFragments error:nil];
//        NSLog(@"%@", array);
    }];
}

@end
