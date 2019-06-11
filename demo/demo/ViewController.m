//
//  ViewController.m
//  demo
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "ViewController.h"
#import <SensorsSDK/SensorsSDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"标题1";
    self.navigationItem.title = @"标题2";
    
    UILabel *customTitleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    customTitleView.text = @"标题3";
    customTitleView.font = [UIFont systemFontOfSize:18];
    customTitleView.textColor = [UIColor blackColor];
    //设置位置在中心
    customTitleView.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = customTitleView;
    
    _uiLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [labelTapGestureRecognizer addTarget:self action:@selector(labelTouchUpInside:)];
    [_uiLabel addGestureRecognizer:labelTapGestureRecognizer];
    
    UILongPressGestureRecognizer *labelLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(labelLongPress:)];
    [_uiLabel addGestureRecognizer:labelLongPressGestureRecognizer];
    
    _uiLabel2.userInteractionEnabled = YES;
    UITapGestureRecognizer *labelTapGestureRecognizer2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    [_uiLabel2 addGestureRecognizer:labelTapGestureRecognizer2];
    
    UITapGestureRecognizer *imageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewTouchUpInside:)];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:imageViewTapGestureRecognizer];
}

-(void) imageViewTouchUpInside:(UITapGestureRecognizer *)recognizer{
    NSLog(@"UIImageView被点击了");
}

-(void) labelTouchUpInside:(UITapGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    NSLog(@"%@被点击了",label.text);
}

-(void) labelLongPress:(UILongPressGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    NSLog(@"%@被长按了",label.text);
}

- (void)setTitle1 {
    
}

- (void)setTitle2 {
    self.title = @"标题1";
}

- (void)setTitle3 {
    self.navigationItem.title = @"标题2";
}

- (void)setTitle4 {
    self.title = @"标题1";
    self.navigationItem.title = @"标题2";
}

- (void)setTitle5 {
    self.navigationItem.title = @"标题2";
    self.title = @"标题1";
}

- (IBAction)buttonOnClick:(id)sender {
    NSLog(@"buttonOnClick");
//    NSArray *arr = @[@(0), @(1)];
//    NSLog(@"%@", arr[2]); //模拟越界异常
}

- (IBAction)switchOnClick:(id)sender {
}

- (IBAction)sliderOnClick:(id)sender {
}

- (IBAction)segmentOnClick:(id)sender {
    NSLog(@"segmentOnClick");
}

- (IBAction)stepperOnClick:(id)sender {
    NSLog(@"stepperOnClick");
}

- (IBAction)trackTimerBeginOnClick:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"doSomething"];
}

- (IBAction)trackTimerEndOnClick:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"doSomething" withProperties:nil];
}

@end
