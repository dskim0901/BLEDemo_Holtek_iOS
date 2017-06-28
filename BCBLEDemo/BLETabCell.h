//
//  BLETabCell.h
//  BCBLEDemo
//
//  Created by holtek on 2016/10/26.
//  Copyright © 2016年 holtek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLETabCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *addrLabel;

@property (weak, nonatomic) IBOutlet UILabel *signalLabel;

//@property (weak, nonatomic) IBOutlet UIImageView *signalImage;

@property (weak, nonatomic) IBOutlet UIImageView *connectImage;

//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *signalWidthRadio;



@end
