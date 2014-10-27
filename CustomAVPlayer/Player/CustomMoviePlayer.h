//
//  CustomMoviePlayer.h
//  avplayerDemo
//
//  Created by ChengZhifeng on 14-10-22.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>


@class WZYPlayerSlider;
@interface CustomMoviePlayer : UIView


@property(nonatomic,retain) AVPlayer *player;

//@property (weak, nonatomic) IBOutlet WZYPlayerSlider *movieSlider;


-(void)updateLayerFrame;
-(void)setVideoFillMode:(NSString *)fillMode;
-(void)setControlsLayout;
@end
