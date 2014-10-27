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
    AVPlayerLayer *playerLayer;

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

- (void)setPlayer:(AVPlayer*)p
{
    [(AVPlayerLayer*)[self layer] setPlayer:p];
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

//    //获取播放的图层
//    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    playerLayer.frame = self.layer.bounds;
//    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    //添加到图层
//    [self.layer addSublayer:playerLayer];
//    //播放
//    [player play];
}

-(void)updateLayerFrame
{
    playerLayer.frame = self.layer.bounds;
}

- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (player.status == AVPlayerStatusReadyToPlay) {
        [self setPlayer:player];
        [player play];
    }
}

@end
