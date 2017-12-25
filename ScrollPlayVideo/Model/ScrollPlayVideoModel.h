//
//  ScrollPlayVideoModel.h
//  ScrollPlayVideo
//
//  Created by 郑旭 on 2017/10/23.
//  Copyright © 2017年 郑旭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScrollPlayVideoModel : NSObject
@property (nonatomic,assign) BOOL isShouldToPlay;
@property (nonatomic,assign) BOOL isLight;

@property (nonatomic,copy) NSString * cover;
@property (nonatomic,copy) NSString * title;
@property (nonatomic,copy) NSString * mp4_url;


@end
