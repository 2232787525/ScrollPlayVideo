# 基于XLVideoPlayer的自动滚动视频播放
![image](https://github.com/2232787525/ScrollPlayVideo/blob/master/QQ20180111-141627-HD.gif)
## 核心代码

### 判断显示中的cell哪个是最佳的显示位置
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


### 让指定的cell播放视频

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
                if(weakSelf.tableView.contentOffset.y + cellHeigh + weakSelf.tableView.frame.size.height > weakSelf.tableView.contentSize.height){
        
                    [weakSelf.tableView setContentOffset:CGPointMake(0, weakSelf.tableView.contentSize.height  -weakSelf.tableView.frame.size.height) animated:YES];
        
                    NSLog(@"滑动到最后一个视频 %f",weakSelf.tableView.contentSize.height  -weakSelf.tableView.frame.size.height);
        
                }else if(weakSelf.tableView.contentOffset.y + cellHeigh + weakSelf.tableView.frame.size.height < weakSelf.tableView.contentSize.height){
        
                    [weakSelf.tableView setContentOffset:CGPointMake(0, weakSelf.tableView.contentOffset.y + cellHeigh) animated:YES];
                    NSLog(@"滑动到下一个视频 %f",weakSelf.tableView.contentOffset.y + cellHeigh);
                }else{
                        //直接播放下一个 因为当前位置正好等于播放最后一条的位置 所以不再执行设置contentOffset的方法
                        [weakSelf playNext];
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
        }



### 调用时机:滚动停止的时候;
```
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
```

### 播放下一个视频

```
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
```
