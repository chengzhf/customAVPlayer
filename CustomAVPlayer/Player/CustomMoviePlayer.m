//
//  CustomMoviePlayer.m
//  avplayerDemo
//
//  Created by ChengZhifeng on 14-10-22.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;

#import "CustomMoviePlayer.h"


@interface CustomMoviePlayer()
{


}
@end

@implementation CustomMoviePlayer

@synthesize player;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

-(AVPlayerLayer*)playerLayer
{
    return (AVPlayerLayer*)[self layer];
}

- (void)setPlayer:(AVPlayer*)p
{
    [(AVPlayerLayer*)[self layer] setPlayer:p];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
    [self playerLayer].videoGravity = fillMode;
}

-(void)awakeFromNib
{
//    NSString *movieURL = @"http://www.jxvdy.com/file/upload/201309/18/18-10-03-19-3.mp4";
    NSString *movieURL = @"http://fkzt.nos.netease.com/ios_sample.mp4";
    
    //使用playerItem获取视频的信息，当前播放时间，总时间等
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:movieURL]];
    //player是视频播放的控制器，可以用来快进播放，暂停等
    player = [AVPlayer playerWithPlayerItem:playerItem];
    
    [player addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
}

-(void)updateLayerFrame
{
    [self playerLayer].frame = self.layer.bounds;
}

- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (player.status == AVPlayerStatusReadyToPlay) {
        [self setPlayer:player];
        [player play];
    }
}

@end
