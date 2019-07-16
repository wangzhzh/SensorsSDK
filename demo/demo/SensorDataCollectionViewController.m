//
//  SensorDataCollectionViewController.m
//  demo
//
//  Created by 张敏超🍎 on 2019/7/16.
//  Copyright © 2019 王灼洲. All rights reserved.
//

#import "SensorDataCollectionViewController.h"

#pragma mark -
@implementation SensorDataCollectionViewCell

@end


#pragma mark -
@interface SensorDataCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *cellTitles;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@end

@implementation SensorDataCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _cellTitles = [NSMutableArray arrayWithCapacity:20];
    for (NSInteger section = 0; section < 20; section++) {
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:8];
        for (NSInteger row = 0; row < 12; row++) {
            [titles addObject:[NSString stringWithFormat:@"Section: %ld\nRow: %ld", section, row]];
        }
        [_cellTitles addObject:titles];
    }
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _cellTitles.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _cellTitles[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SensorDataCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
    cell.titleLabel.text = _cellTitles[indexPath.section][indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Did Select Item: %ld, %ld", indexPath.section, indexPath.item);
}

@end