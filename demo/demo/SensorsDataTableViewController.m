//
//  SensorsDataTableViewController.m
//  demo
//
//  Created by MC on 2019/6/22.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorsDataTableViewController.h"

@interface SensorsDataTableViewController ()
@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *cellTitles;
@end

@implementation SensorsDataTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _cellTitles = [NSMutableArray arrayWithCapacity:10];
    for (NSInteger section = 0; section < 10; section++) {
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:8];
        for (NSInteger row = 0; row < 8; row++) {
            [titles addObject:[NSString stringWithFormat:@"Section: %ld, Row: %ld", section, row]];
        }
        [_cellTitles addObject:titles];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _cellTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellTitles[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = _cellTitles[indexPath.section][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", indexPath);
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SensorsDataTableViewController *vc = [sb instantiateViewControllerWithIdentifier:@"SensorsDataTableViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row % 2 == 0 ? 44 : 80;
}

@end
