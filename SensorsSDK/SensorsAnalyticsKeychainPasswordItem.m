//
//  SensorsAnalyticsKeychainPasswordItem.m
//  SensorsSDK
//
//  Created by 张敏超🍎 on 2019/12/3.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsKeychainPasswordItem.h"
#import <Security/Security.h>

@interface SensorsAnalyticsKeychainPasswordItem ()

@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *account;
@property (nonatomic, strong) NSString *accessGroup;

@end

@implementation SensorsAnalyticsKeychainPasswordItem

- (instancetype)initWithService:(NSString *)service account:(NSString *)account {
    return [self initWithService:service account:account accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service account:(NSString *)account accessGroup:(nullable NSString *)accessGroup {
    self = [super init];
    if (self) {
        _service = service;
        _account = account;
        _accessGroup = accessGroup;
    }
    return self;
}

- (nullable NSString *)readPassword {
    NSMutableDictionary *query = [SensorsAnalyticsKeychainPasswordItem keychainQueryWithService:self.service account:self.account accessGroup:self.accessGroup];
    query[(NSString *)kSecMatchLimit] = (id)kSecMatchLimitOne;
    query[(NSString *)kSecReturnAttributes] = (id)kCFBooleanTrue;
    query[(NSString *)kSecReturnData] = (id)kCFBooleanTrue;

    CFTypeRef queryResult;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &queryResult);

    if (status == errSecItemNotFound) {
        return nil;
    }
    if (status != noErr) {
        NSLog(@"readPassword error %d", (int)status);
        return nil;
    }

    NSData *passwordData = [(__bridge_transfer NSDictionary *)queryResult objectForKey:(NSString *)kSecValueData];
    if (!passwordData) {
        return nil;
    }
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    NSLog(@"readPassword %@", password);
    return password;
}

- (void)savePassword:(NSString *)password {
    NSData *encodedPassword = [password dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableDictionary *query = [SensorsAnalyticsKeychainPasswordItem keychainQueryWithService:self.service account:self.account accessGroup:self.accessGroup];

    NSString *originalPassword = [self readPassword];
    if (originalPassword) {
        NSMutableDictionary *attributesToUpdate = [[NSMutableDictionary alloc] init];
        attributesToUpdate[(NSString *)kSecValueData] = encodedPassword;

        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
        if (status == noErr) {
            NSLog(@"savePassword update ok");
        } else {
            NSLog(@"savePassword update error %d", (int)status);
        }
    } else {
        [query setObject:encodedPassword forKey:(id)kSecValueData];
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (status == noErr) {
            NSLog(@"savePassword add ok");
        } else {
            NSLog(@"savePassword add error %d", (int)status);
        }
    }
}

- (void)renameAccount:(NSString *)account {
    NSMutableDictionary *attributesToUpdate = [[NSMutableDictionary alloc] init];
    attributesToUpdate[(NSString *)kSecAttrAccount] = account;

    NSMutableDictionary *query = [SensorsAnalyticsKeychainPasswordItem keychainQueryWithService:self.service account:self.account accessGroup:self.accessGroup];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    
    if (status == noErr && status == errSecItemNotFound) {
        self.account = account;
    } else {
        NSLog(@"renameAccount error %d", (int)status);
    }
}

- (void)deleteItem {
    NSMutableDictionary *query = [SensorsAnalyticsKeychainPasswordItem keychainQueryWithService:self.service account:self.account accessGroup:self.accessGroup];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

    if (status != noErr && status != errSecItemNotFound) {
        NSLog(@"deleteItem %d", (int)status);
    }
}

#pragma mark - Private

+ (NSMutableDictionary *)keychainQueryWithService:(NSString *)service account:(NSString *)account accessGroup:(nullable NSString *)accessGroup {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    query[(NSString *)kSecClass] = (NSString *)kSecClassGenericPassword;
    query[(NSString *)kSecAttrService] = service;
    query[(NSString *)kSecAttrAccount] = account;
    query[(NSString *)kSecAttrAccessGroup] = accessGroup;
    return query;
}

@end
