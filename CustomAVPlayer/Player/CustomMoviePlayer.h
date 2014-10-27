//
//  CustomMoviePlayer.h
//  avplayerDemo
//
//  Created by ChengZhifeng on 14-10-22.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//



#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import "CustomMoviePlayerConstant.h"

@class CustomMoviePlayer;
@class WZYPlayerSlider;

@protocol CustomMoviePlayerDelegate <NSObject>
- (void)pulldown:(CustomMoviePlayer *)customMoviePlayer;
- (void)snsShare:(CustomMoviePlayer *)customMoviePlayer;
@end


@interface CustomMoviePlayer : UIView

@property(nonatomic,retain) AVPlayer *player;
@property (assign, nonatomic)  VideoState videoState;
@property (copy,nonatomic) NSString *videoURL;
@property (copy,nonatomic) NSString *previewImageURL;
@property (assign,nonatomic) id<CustomMoviePlayerDelegate> delegate;
-(void)updateLayerFrame;
-(void)setVideoFillMode:(NSString *)fillMode;
-(void)setControlsLayout;
@end
