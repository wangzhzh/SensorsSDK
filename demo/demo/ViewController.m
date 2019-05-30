//
//  ViewController.m
//  demo
//
//  Created by 王灼洲 on 2019/5/23.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "ViewController.h"

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
}

- (IBAction)switchOnClick:(id)sender {
}

- (IBAction)sliderOnClick:(id)sender {
}


@end
