//
//  SensorsAnalyticsKeychainItem.m
//  SensorsSDK
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsKeychainItem.h"
#import <Security/Security.h>

@interface SensorsAnalyticsKeychainItem ()

@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *accessGroup;
@property (nonatomic, strong) NSString *key;

@end

@implementation SensorsAnalyticsKeychainItem

- (instancetype)initWithService:(NSString *)service key:(NSString *)key {
    return [self initWithService:service accessGroup:nil key:key];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(nullable NSString *)accessGroup key:(NSString *)key {
    self = [super init];
    if (self) {
        _service = service;
        _key = key;
        _accessGroup = accessGroup;
    }
    return self;
}

- (nullable NSString *)value {
    NSMutableDictionary *query = [SensorsAnalyticsKeychainItem keychainQueryWithService:self.service accessGroup:self.accessGroup key:self.key];
    query[(NSString *)kSecMatchLimit] = (id)kSecMatchLimitOne;
    query[(NSString *)kSecReturnAttributes] = (id)kCFBooleanTrue;
    query[(NSString *)kSecReturnData] = (id)kCFBooleanTrue;

    CFTypeRef queryResult;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &queryResult);

    if (status == errSecItemNotFound) {
        return nil;
    }
    if (status != noErr) {
        NSLog(@"Get item value error %d", (int)status);
        return nil;
    }

    NSData *data = [(__bridge_transfer NSDictionary *)queryResult objectForKey:(NSString *)kSecValueData];
    if (!data) {
        return nil;
    }
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"Get item value %@", value);
    return value;
}

- (void)update:(NSString *)value {
    NSData *encodedValue = [value dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableDictionary *query = [SensorsAnalyticsKeychainItem keychainQueryWithService:self.service accessGroup:self.accessGroup key:self.key];

    NSString *originalValue = [self value];
    if (originalValue) {
        NSMutableDictionary *attributesToUpdate = [[NSMutableDictionary alloc] init];
        attributesToUpdate[(NSString *)kSecValueData] = encodedValue;

        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
        if (status == noErr) {
            NSLog(@"update item ok");
        } else {
            NSLog(@"update item error %d", (int)status);
        }
    } else {
        [query setObject:encodedValue forKey:(id)kSecValueData];
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (status == noErr) {
            NSLog(@"add item ok");
        } else {
            NSLog(@"add item error %d", (int)status);
        }
    }
}

- (void)remove {
    NSMutableDictionary *query = [SensorsAnalyticsKeychainItem keychainQueryWithService:self.service accessGroup:self.accessGroup key:self.key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

    if (status != noErr && status != errSecItemNotFound) {
        NSLog(@"remove item %d", (int)status);
    }
}

#pragma mark - Private

+ (NSMutableDictionary *)keychainQueryWithService:(NSString *)service accessGroup:(nullable NSString *)accessGroup key:(NSString *)key {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    query[(NSString *)kSecClass] = (NSString *)kSecClassGenericPassword;
    query[(NSString *)kSecAttrService] = service;
    query[(NSString *)kSecAttrAccount] = key;
    query[(NSString *)kSecAttrAccessGroup] = accessGroup;
    return query;
}

@end
