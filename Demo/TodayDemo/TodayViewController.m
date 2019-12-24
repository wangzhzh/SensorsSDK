//
//  TodayViewController.m
//  TodayDemo
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <SensorsAppExtensionSDK/SensorsAppExtensionSDK.h>

static NSString * const kTodayDemoResult = @"com.wangzhzh.demo.result";
static NSString * const kGroupIdentifier = @"group.com.wangzhzh.demo.extension";

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UILabel *numLabel;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupIdentifier];
//    int result = [[userDefaults objectForKey:kTodayDemoResult] intValue];
//    self.numLabel.text = [NSString stringWithFormat:@"%d", result];

    NSURL *url = [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:kGroupIdentifier] URLByAppendingPathComponent:@"TodayResult.txt"];
    int result = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil] intValue];
    self.numLabel.text = [NSString stringWithFormat:@"%d", result];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (IBAction)plusAction:(UIButton *)sender {
    self.numLabel.text = [NSString stringWithFormat:@"%d", self.numLabel.text.intValue + 1];

    [self saveToUserDefaultsWithString:self.numLabel.text];

    [self saveToFileWithString:self.numLabel.text];

    [[SensorsAnalyticsExtensionDataManager sharedInstance] track:@"today_plus" properties:@{@"value": @(self.numLabel.text.intValue)} applicationGroupIdentifier:kGroupIdentifier];
}

- (IBAction)minusAction:(UIButton *)sender {
    self.numLabel.text = [NSString stringWithFormat:@"%d", self.numLabel.text.intValue - 1];

    [self saveToUserDefaultsWithString:self.numLabel.text];

    [self saveToFileWithString:self.numLabel.text];

    [[SensorsAnalyticsExtensionDataManager sharedInstance] track:@"today_minus" properties:@{@"value": @(self.numLabel.text.intValue)} applicationGroupIdentifier:kGroupIdentifier];
}

- (void)saveToUserDefaultsWithString:(NSString *)string {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupIdentifier];
    [userDefaults setObject:string forKey:kTodayDemoResult];
}

- (void)saveToFileWithString:(NSString *)string {
    NSURL *url = [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:kGroupIdentifier] URLByAppendingPathComponent:@"TodayResult.txt"];
    [string writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
