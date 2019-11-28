//
//  SensorsDataWebViewViewController.m
//  demo
//
//  Created by 张敏超🍎 on 2019/9/28.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsDataWebViewViewController.h"
#import <SensorsSDK/SensorsSDK.h>
#import <WebKit/WebKit.h>

@interface SensorsDataWebViewViewController () <UIWebViewDelegate, WKNavigationDelegate, WKScriptMessageHandler>

//@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation SensorsDataWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

//    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
//    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    _webView.delegate = self;
//    [self.view addSubview:_webView];

    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.navigationDelegate = self;
    [self.view addSubview:_webView];

    [_webView.configuration.userContentController addScriptMessageHandler:self name:@"sensorsData"];

    NSURL *url = [NSBundle.mainBundle.bundleURL URLByAppendingPathComponent:@"sensorsdata.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];

//    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.sensorsdata.cn"]];
//    [_webView loadRequest:req];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[SensorsAnalyticsSDK sharedInstance] shouldTrackWithWebView:webView request:request]) {
        return NO;
    }
    return YES;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([[SensorsAnalyticsSDK sharedInstance] shouldTrackWithWebView:webView request:navigationAction.request]) {
        return decisionHandler(WKNavigationActionPolicyCancel);
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.body[@"command"] isEqual:@"track"]) {
        [[SensorsAnalyticsSDK sharedInstance] trackFromH5WithEvent:message.body[@"event"]];
//        [[SensorsAnalyticsSDK sharedInstance] track:message.body[@"event"] properties:message.body[@"properties"]];
    }
}

@end
