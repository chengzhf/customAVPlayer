//
//  AVPlayerDemoPlaybackView.h
//  CustomAVPlayer
//
//  Created by chengzhifeng on 14-10-27.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface AVPlayerDemoPlaybackView : UIView

@property (nonatomic, retain) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
