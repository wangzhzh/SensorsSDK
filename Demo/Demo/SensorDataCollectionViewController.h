//
//  SensorDataCollectionViewController.h
//  demo
//
//  Created by 王灼洲 on 2019/08/08.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorDataCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@interface SensorDataCollectionViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
