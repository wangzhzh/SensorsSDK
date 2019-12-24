//
//  ViewController.m
//  demo
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "ViewController.h"
#import <SensorsSDK/SensorsSDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"awakeFromNib");
}

- (void)loadView {
    [super loadView];
    NSLog(@"awakeFromNib");
}

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
    
    _tappedLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tapAction:)];
    [_tappedLabel addGestureRecognizer:tap];

//    UIButton *btn = [[UIButton alloc]  initWithFrame:CGRectMake(0, 0, 100, 200)];
//    [btn setTitle:@"jjjjj" forState:UIControlStateNormal];
//    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [btn addTarget:self action:@selector(buttonOnClick:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn];

//    UILongPressGestureRecognizer *labelLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(labelLongPress:)];
//    [_uiLabel addGestureRecognizer:labelLongPressGestureRecognizer];
//    
//    _uiLabel2.userInteractionEnabled = YES;
//    UITapGestureRecognizer *labelTapGestureRecognizer2 = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
//    [_uiLabel2 addGestureRecognizer:labelTapGestureRecognizer2];
//    
//    UITapGestureRecognizer *imageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewTouchUpInside:)];
//    _imageView.userInteractionEnabled = YES;
//    [_imageView addGestureRecognizer:imageViewTapGestureRecognizer];
}

-(void) imageViewTouchUpInside:(UITapGestureRecognizer *)recognizer{
    NSLog(@"UIImageView被点击了");
}

- (void)tapAction:(UITapGestureRecognizer *)sender {
    UILabel *label= (UILabel*)sender.view;
    NSLog(@"%@被点击了", label.text);
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
//    [sender addTarget:self action:@selector(segmentOnClick:) forControlEvents:UIControlEventTouchDown];
    [sender removeTarget:self action:@selector(buttonOnClick:) forControlEvents:UIControlEventTouchUpInside];
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

- (IBAction)trackTimerPauseOnClick:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"doSomething"];
}

- (IBAction)trackTimerResumeOnClick:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:@"doSomething"];
}

- (IBAction)trackTimerEndOnClick:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"doSomething" properties:nil];
}

@end
