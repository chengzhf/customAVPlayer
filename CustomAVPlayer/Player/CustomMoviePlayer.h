//
//  CustomMoviePlayer.h
//  avplayerDemo
//
//  Created by ChengZhifeng on 14-10-22.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

@interface CustomMoviePlayer : UIView


@property(nonatomic,retain) AVPlayer *player;

-(void)updateLayerFrame;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
