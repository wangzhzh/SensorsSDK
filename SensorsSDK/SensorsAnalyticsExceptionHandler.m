//
//  SensorsAnalyticsExceptionHandler.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/6/9.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsAnalyticsExceptionHandler.h"
#import "SensorsAnalyticsSDK.h"
#include <libkern/OSAtomic.h>

static volatile int32_t UncaughtExceptionCount = 0;
static const int32_t UncaughtExceptionMaximum = 10;

@interface SensorsAnalyticsExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic) SensorsAnalyticsSDK *sensorsAnalyticsSDKInstances;

@end

@implementation SensorsAnalyticsExceptionHandler

+ (instancetype)sharedHandler {
    static SensorsAnalyticsExceptionHandler *gSharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gSharedHandler = [[SensorsAnalyticsExceptionHandler alloc] init];
        
    });
    return gSharedHandler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Install our handler
        [self setupHandlers];
    }
    return self;
}

- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance {
    NSParameterAssert(instance != nil);
    self.sensorsAnalyticsSDKInstances = instance;
}

- (void)setupHandlers {
    _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&SAHandleException);
}

static void SAHandleException(NSException *exception) {
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedHandler];
    
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount <= UncaughtExceptionMaximum) {
        [handler sa_handleUncaughtException:exception];
    }
    
    if (handler.defaultExceptionHandler) {
        handler.defaultExceptionHandler(exception);
    }
}

- (void) sa_handleUncaughtException:(NSException *)exception {
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedHandler];
    [_sensorsAnalyticsSDKInstances track:@"dddd" andProperties:nil];
}

@end
