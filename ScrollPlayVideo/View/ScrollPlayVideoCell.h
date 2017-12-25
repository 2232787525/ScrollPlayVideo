//
//  ScrollPlayVideoCell.h
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/23.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScrollPlayVideoModel.h"

@class ScrollPlayVideoCell;
@protocol ScrollPlayVideoCellDelegate<NSObject>
-(void)playerTapActionWithIsShouldToHideSubviews:(BOOL)isHide;
- (void)playButtonClick:(UIButton *)sender;
@end
@interface ScrollPlayVideoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *topblackView;
@property (weak, nonatomic) IBOutlet UIView *bottomBlackView;
@property (weak, nonatomic) IBOutlet UILabel *lab;

@property (weak, nonatomic) IBOutlet UIView *videoFirstImageView;
@property (nonatomic,weak) id<ScrollPlayVideoCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *videoBackView;

@property (nonatomic,assign) NSInteger row;
@property (nonatomic,retain) ScrollPlayVideoModel * model;



@end
