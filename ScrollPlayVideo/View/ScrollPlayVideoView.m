//
//  ScrollPlayVideoView.m
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/20.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import "ScrollPlayVideoView.h"
#import "ScrollPlayVideoHeader.h"
#import "ScrollPlayVideoCell.h"
#import "ScrollPlayVideoModel.h"
#import <AFNetworking.h>

#import "XLVideoPlayer.h"

#define videoListUrl @"http://c.3g.163.com/nc/video/list/VAP4BFR16/y/0-10.html"
#define cellHeigh 300


static NSString *cellIdentify = @"ScrollPlayVideoCell";
@interface ScrollPlayVideoView()<UITableViewDelegate,UITableViewDataSource,ScrollPlayVideoCellDelegate>{
    BOOL rate;
    XLVideoPlayer *_player;
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;

@property (nonatomic,assign) NSInteger lastOrCurrentPlayIndex;
@property (nonatomic,assign) NSInteger lastOrCurrentLightIndex;

@property (nonatomic,assign) NSInteger lastPlayCell;

//记录偏移值,用于判断上滑还是下滑
@property (nonatomic,assign) CGFloat lastScrollViewContentOffsetY;
//Yes-往下滑,NO-往上滑
@property (nonatomic,assign) BOOL isScrollDownward;
@end
@implementation ScrollPlayVideoView
#pragma mark - Life Cycle
- (instancetype)init{
    self = [super init];
    if (self) {
        [self initData];
        [self addSubViews];
        [self setUI];
        
        [self fetchVideoListData];
    }
    return self;
}

//TODO:播放结束的回调方法
-(void)SBPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification{
    NSLog(@"滑动到下一个视频 %f",self.tableView.contentOffset.y + cellHeigh);
    
    if (self.lastPlayCell != self.dataArray.count-1) {
        
        if(self.tableView.contentOffset.y + cellHeigh + self.tableView.frame.size.height + 1 >= self.tableView.contentSize.height){
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - cellHeigh -self.tableView.frame.size.height) animated:YES];

        }else{
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + cellHeigh) animated:YES];
        }
    }
}

#pragma mark - Private Methods

//网络请求
- (void)fetchVideoListData {
    
    [self.dataArray removeAllObjects];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:videoListUrl parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"%@", responseObject);
        NSArray *dataArray = responseObject[@"VAP4BFR16"];
        
        for (NSMutableDictionary *dic in dataArray) {
            ScrollPlayVideoModel *model = [[ScrollPlayVideoModel alloc] init];
            model.cover = dic[@"cover"];
            model.title = dic[@"title"];
            model.mp4_url = dic[@"mp4_url"];
            model.isShouldToPlay = NO;
            [self.dataArray addObject:model];
            
        }
        [self.tableView reloadData];
        
        //设置初次播放
        [self setStartTimeValue:0];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

- (void)initData
{
    self.lastOrCurrentPlayIndex = 0;
    self.lastOrCurrentLightIndex = 0;
    self.lastPlayCell = 0;

}

- (void)addSubViews{
    [self addSubview:self.tableView];
}

- (void)setUI{
    [self.tableView registerNib:[UINib nibWithNibName:cellIdentify bundle:nil] forCellReuseIdentifier:cellIdentify];
}

- (void)setStartTimeValue:(CGFloat)startTimeValue
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:path];

    [self cellPlay:cell];
}

#pragma mark - ScrollPlayVideoCellDelegate
- (void)playerTapActionWithIsShouldToHideSubviews:(BOOL)isHide{
    ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.lastOrCurrentPlayIndex inSection:0]];
    cell.bottomBlackView.hidden = !isHide;
}

- (void)playButtonClick:(UIButton *)sender{
    NSInteger row = sender.tag-788;
    if (row!=self.lastOrCurrentPlayIndex) {
        [self stopVideoWithShouldToStopIndex:self.lastOrCurrentPlayIndex];
        self.lastOrCurrentPlayIndex = row;
        [self playVideoWithShouldToPlayIndex:self.lastOrCurrentPlayIndex];
        self.lastOrCurrentLightIndex = row;
        [self shouldLightCellWithShouldLightIndex:self.lastOrCurrentLightIndex];
    }
}
#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ScrollPlayVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    cell.row = indexPath.row;
    cell.model =self.dataArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return cellHeigh;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.001;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.001;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

    //判断滚动方向
    if (scrollView.contentOffset.y>self.lastScrollViewContentOffsetY) {
        self.isScrollDownward = YES;
    }else{
        self.isScrollDownward = NO;
    }
    self.lastScrollViewContentOffsetY = scrollView.contentOffset.y;
    
    //停止当前播放的
    [self stopCurrentPlayingCell];
    
    //找出适合播放的并点亮
    [self filterShouldLightCellWithScrollDirection:self.isScrollDownward];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    if (velocity.y >0 || velocity.y < 0) {
        rate = YES;
    }else{
        rate = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (rate == YES) {
        //停止的时候找出最合适的播放
        NSLog(@"滑动停止时播放1");
        [self filterShouldPlayCellWithScrollDirection:self.isScrollDownward];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(decelerate == NO){
        //停止的时候找出最合适的播放
        NSLog(@"滑动停止时播放2");
        [self filterShouldPlayCellWithScrollDirection:self.isScrollDownward];
    }
}

//setContentOffset: animation:
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    
    [self playNext];
}

-(void)playNext{
    
    //中部(找出可见cell中最合适的一个进行播放)
    NSArray *cellsArray = [self.tableView visibleCells];
    [self stopVideoWithShouldToStopIndex:self.lastPlayCell];
    
    for (ScrollPlayVideoCell *cell in cellsArray) {
        
        if (cell.row == self.lastPlayCell + 1) {
            NSLog(@"播放下一个视频： %ld",(long)cell.row);
            [self cellPlay:cell];
            break;
        }
    }
}

#pragma mark - 明暗控制
- (void)filterShouldLightCellWithScrollDirection:(BOOL)isScrollDownward{
    
    ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.lastOrCurrentLightIndex inSection:0]];
    cell.topblackView.hidden = NO;
    //顶部
    if (self.tableView.contentOffset.y<=0) {
        [self shouldLightCellWithShouldLightIndex:0];
        self.lastOrCurrentLightIndex = 0;
        return;
    }

    //底
    if (self.tableView.contentOffset.y+self.tableView.frame.size.height>=self.tableView.contentSize.height) {
        //其他的已经暂停播放
        [self shouldLightCellWithShouldLightIndex:self.dataArray.count-1];
        self.lastOrCurrentLightIndex=self.dataArray.count-1;
        return;
    }
    NSArray *cellsArray = [self.tableView visibleCells];
    NSArray *newArray = nil;
    if (!isScrollDownward) {
        newArray = [cellsArray reverseObjectEnumerator].allObjects;
    }else{
        newArray = cellsArray;
    }
    [newArray enumerateObjectsUsingBlock:^(ScrollPlayVideoCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        //NSLog(@"合适的播放视频： %ld",(long)cell.row);
        
        CGRect rect = [cell.videoFirstImageView convertRect:cell.videoFirstImageView.bounds toView:self];
        CGFloat topSpacing = rect.origin.y;
        CGFloat bottomSpacing = self.frame.size.height-rect.origin.y-rect.size.height;
        if (topSpacing>=-rect.size.height/3&&bottomSpacing>=-rect.size.height/3) {
            if (self.lastOrCurrentPlayIndex==-1) {
                self.lastOrCurrentLightIndex = cell.row;
            }
            *stop = YES;
        }
    }];
    [self shouldLightCellWithShouldLightIndex:self.lastOrCurrentLightIndex];
    
}

- (void)shouldLightCellWithShouldLightIndex:(NSInteger)shouldLIghtIndex
{
    
    ScrollPlayVideoCell *cell2 = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:shouldLIghtIndex inSection:0]];
    cell2.topblackView.hidden = YES;
}
#pragma mark - 播放暂停-播放视频
- (void)filterShouldPlayCellWithScrollDirection:(BOOL)isScrollDownward
{

    //顶部
    if (self.tableView.contentOffset.y<=0) {
        //其他的已经暂停播放
        if (self.lastOrCurrentPlayIndex==-1) {
            [self playVideoWithShouldToPlayIndex:0];
        }else{
            //第一个正在播放
            if (self.lastOrCurrentPlayIndex==0) {
                return;
            }
            //其他的没有暂停播放,先暂停其他的再播放第一个
            [self stopVideoWithShouldToStopIndex:self.lastOrCurrentPlayIndex];
            [self playVideoWithShouldToPlayIndex:0];
        }
        return;
    }
    
    //底部
    if (self.tableView.contentOffset.y+self.tableView.frame.size.height+1>=self.tableView.contentSize.height) {
        //其他的已经暂停播放
        if (self.lastOrCurrentPlayIndex==-1) {
            [self playVideoWithShouldToPlayIndex:self.dataArray.count-1];
        }else{
            //最后一个正在播放
            if (self.lastOrCurrentPlayIndex==self.dataArray.count-1) {
                return;
            }
            //其他的没有暂停播放,先暂停其他的再播放最后一个
            [self stopVideoWithShouldToStopIndex:self.lastOrCurrentPlayIndex];
            [self playVideoWithShouldToPlayIndex:self.dataArray.count-1];
        }
        return;
    }

    [self stopVideoWithShouldToStopIndex:self.lastPlayCell];

    //中部(找出可见cell中最合适的一个进行播放)
    NSArray *cellsArray = [self.tableView visibleCells];
    NSArray *newArray = nil;
    if (!isScrollDownward) {
        newArray = [cellsArray reverseObjectEnumerator].allObjects;
    }else{
        newArray = cellsArray;
    }
    [newArray enumerateObjectsUsingBlock:^(ScrollPlayVideoCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"播放视频 %ld",(long)cell.row);

        CGRect rect = [cell.videoFirstImageView convertRect:cell.videoFirstImageView.bounds toView:self];
        CGFloat topSpacing = rect.origin.y;
        CGFloat bottomSpacing = self.frame.size.height-rect.origin.y-rect.size.height;
        if (topSpacing>=-rect.size.height/3&&bottomSpacing>=-rect.size.height/3) {
            if (self.lastOrCurrentPlayIndex==-1) {
                if (self.lastOrCurrentPlayIndex!=cell.row) {
                    [self cellPlay:cell];
                }
            }
            *stop = YES;
        }else{
            [self stopVideoWithShouldToStopIndex:cell.row];

        }
    }];
}
- (void)stopCurrentPlayingCell
{
    //避免第一次播放的时候被暂停
    if (self.tableView.contentOffset.y<=0) {
        return;
    }
    if (self.lastOrCurrentPlayIndex!=-1) {
        ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.lastOrCurrentPlayIndex inSection:0]];
        CGRect rect = [cell.videoFirstImageView convertRect:cell.videoFirstImageView.bounds toView:self];
        CGFloat topSpacing = rect.origin.y;
        CGFloat bottomSpacing = self.frame.size.height-rect.origin.y-rect.size.height;
        //当视频播放部分移除可见区域1/3的时候暂停
        if (topSpacing<-rect.size.height/3||bottomSpacing<-rect.size.height/3) {
            self.lastOrCurrentPlayIndex  = -1;
        }
    }
}
- (void)playVideoWithShouldToPlayIndex:(NSInteger)shouldToPlayIndex{
    NSIndexPath *path = [NSIndexPath indexPathForRow:shouldToPlayIndex inSection:0];
    ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:path];
    [self cellPlay:cell];
}

-(void)cellPlay:(ScrollPlayVideoCell *)cell{

    if(self.dataArray.count<=0){
        return;
    }
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:cell.row inSection:0];
    
    __weak typeof(self) weakSelf = self;
    __weak XLVideoPlayer *beplayer = _player;
    if (_player && cell.row == self.lastPlayCell) {
        return;
    }
    
    [_player removeFromSuperview];
    
    _player = [[XLVideoPlayer alloc] init];
    _player.completedPlayingBlock = ^(XLVideoPlayer *player) {
        
        if (weakSelf.lastPlayCell != weakSelf.dataArray.count-1) {
            if(weakSelf.tableView.contentOffset.y + cellHeigh + weakSelf.tableView.frame.size.height + 1 >= weakSelf.tableView.contentSize.height){
                [weakSelf.tableView setContentOffset:CGPointMake(0, weakSelf.tableView.contentSize.height  -weakSelf.tableView.frame.size.height) animated:YES];
                
                NSLog(@"滑动到最后一个视频 %f",weakSelf.tableView.contentSize.height  -weakSelf.tableView.frame.size.height);

            }else{
                [weakSelf.tableView setContentOffset:CGPointMake(0, weakSelf.tableView.contentOffset.y + cellHeigh) animated:YES];
                NSLog(@"滑动到下一个视频 %f",weakSelf.tableView.contentOffset.y + cellHeigh);

            }
        }
        [beplayer setStatusBarHidden:NO];
    };

    _player.slider.value = 0;
    _player.videoUrl = cell.model.mp4_url;// item.mp4_url;
    [_player playerBindTableView:self.tableView currentIndexPath:path];
    _player.frame = cell.videoBackView.bounds;
    [_player.player play];
    //在cell上加载播放器
    [cell.contentView addSubview:_player];

    self.lastOrCurrentPlayIndex = cell.row;
    self.lastPlayCell = cell.row;
    cell.topblackView.hidden = YES;
    cell.bottomBlackView.hidden = YES;

}


- (void)stopVideoWithShouldToStopIndex:(NSInteger)shouldToStopIndex{
    ScrollPlayVideoCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:shouldToStopIndex inSection:0]];
    cell.topblackView.hidden = NO;
}

#pragma mark - Getters & Setters
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScrollPlayScreenWidth, ScrollPlayScreenHeight-64) style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.sectionFooterHeight = 1;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScrollPlayScreenWidth, 0.001)];
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScrollPlayScreenWidth, 0.001)];
        _tableView.separatorStyle = NO;
    }
    return _tableView;
}

- (NSMutableArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}
@end
