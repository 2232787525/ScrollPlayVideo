//
//  ScrollPlayVideoCell.m
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/23.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import "ScrollPlayVideoCell.h"
#import "ScrollPlayVideoHeader.h"
#import <UIImageView+WebCache.h>
@interface ScrollPlayVideoCell()
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *headImageButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIImageView *bgimg;
@property (weak, nonatomic) IBOutlet UILabel *infoLLab;


@end
@implementation ScrollPlayVideoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addSubviews];
    [self setUI];
}
- (void)setUI
{
    self.videoBackView.userInteractionEnabled = YES;
    [self.likeButton setImage:[UIImage imageNamed:@"ICON点赞"] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"ICON已点赞"] forState:UIControlStateSelected];
}
- (void)addSubviews
{
}

- (IBAction)playButtonClick:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if ([self.delegate respondsToSelector:@selector(playButtonClick:)]) {
        
        [self.delegate playButtonClick:sender];
    }
}

- (IBAction)headImageButtonClick:(id)sender {
}
- (IBAction)commentButtonClick:(id)sender {
}
- (IBAction)likeButtonClick:(UIButton *)sender {
    
    [sender setSelected:!sender.isSelected];
    NSInteger likeCount = [sender.titleLabel.text integerValue];
    if (sender.isSelected) {
        likeCount += 1;
    }else
    {
        likeCount -= 1;
    }
    [sender setTitle:[NSString stringWithFormat:@"%ld",likeCount] forState:UIControlStateNormal];
    
}
- (IBAction)shareButtonClike:(id)sender {
}
#pragma mark - SBPlayerDelegate
- (void)playerTapActionWithIsShouldToHideSubviews:(BOOL)isHide
{
    if ([self.delegate respondsToSelector:@selector(playerTapActionWithIsShouldToHideSubviews:)]) {
        [self.delegate playerTapActionWithIsShouldToHideSubviews:isHide];
    }
}
- (void)setRow:(NSInteger)row
{
    _row = row;
    self.playButton.tag = 788+row;
    self.lab.text = [NSString stringWithFormat:@"%ld",row];
}


-(void)setModel:(ScrollPlayVideoModel *)model{
    
    _model = model;
    [_bgimg sd_setImageWithURL:[NSURL URLWithString:model.cover] placeholderImage:[UIImage imageNamed:@"timg"]];
    _infoLLab.text = model.title;
    
    
}
@end
