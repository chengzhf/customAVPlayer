//
//  CustomMoviePlayer.m
//  avplayerDemo
//
//  Created by ChengZhifeng on 14-10-22.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;


#define FRAME_HEIGHT self.bounds.size.height
#define FRAME_WIDTH self.bounds.size.width
#define TOP_BAR_HEIGHT 70
#define BOTTOM_BAR_HEIGHT 70
#define SHARE_BTN_WIDTH 64
#define STATE_IMAGE_WIDTH 64
#define BOTTOM_CONTROL_HEIGHT 64
#define FULL_SCREEN_WIDTH 64
#define FULL_SCREEN_HEIGHT 64
#define SLIDE_TIMER_INTERVAL 5
#define PLAY_TIMER_INTERVAL 0.2
#define BUFFER_TIMER_INTERVAL 0.5

#import "CustomMoviePlayer.h"
#import "WZYPlayerSlider.h"


@interface CustomMoviePlayer()
{
    //视频概要图
    UIView *thumbImageView;
    
    //更多功能层
    UIView *controlsView;
    
    //更多功能层里面的底部bar
    UIView *bottomBarView;
    //更多功能层里面的顶部bar
    UIView *topBarView;
    
    //播放、暂停、重放。也放在更多功能层里
    UIButton *stateControlBtn;
    
    //放在bottomBarView里的控件
    //视频总时间和已播放时间
    UILabel *durationLabel;
    UILabel *playDurationLabel;
    //视频进度条
    WZYPlayerSlider *movieSlider;
    //全屏按钮
    UIButton *fullScreenBtn;
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


#pragma mark -  get and set methods
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


#pragma  mark - init methods
-(void)awakeFromNib
{
//    NSString *movieURL = @"http://www.jxvdy.com/file/upload/201309/18/18-10-03-19-3.mp4";
    NSString *movieURL = @"http://fkzt.nos.netease.com/ios_sample.mp4";
    
    //使用playerItem获取视频的信息，当前播放时间，总时间等
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:movieURL]];
    //player是视频播放的控制器，可以用来快进播放，暂停等
    player = [AVPlayer playerWithPlayerItem:playerItem];
    
    [player addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    
    [self initCustomControls];
}

-(void)layoutSubviews
{
    [self setControlsLayout];
}


//初始化控件布局。。布局与状态，逻辑要分开。。等弄到旋转的时候就拆吧。。
-(void)initCustomControls
{
    controlsView = [[UIView alloc] init];
    [self addSubview:controlsView];
    
    topBarView = [[UIView alloc] init];
    bottomBarView = [[UIView alloc] init];
    
    [bottomBarView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]];
    [controlsView addSubview:topBarView];
    [controlsView addSubview:bottomBarView];
    

    //播放、暂停、重放
    stateControlBtn = [[UIButton alloc] init];
    [stateControlBtn setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [stateControlBtn addTarget:self action:@selector(didStateControl:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview:stateControlBtn];
    
    
    //视频总时间和已播放时间
    playDurationLabel = [[UILabel alloc] init];
    durationLabel = [[UILabel alloc] init];
    [durationLabel setText:@"0:00"];
    [playDurationLabel setText:@"000:00"];
    [bottomBarView addSubview:durationLabel];
    [bottomBarView addSubview:playDurationLabel];

    
    //滑动条
    movieSlider = [[WZYPlayerSlider alloc] init];
    movieSlider.maximumValue = 60.0f;
    movieSlider.duration = 60.0f;
    movieSlider.availableDuration = 30.0f;
    movieSlider.value = 10.1F;
    [movieSlider.layer setBorderColor:[UIColor redColor].CGColor];
    [movieSlider.layer setBorderWidth:1.0f];
    [movieSlider addTarget:self action:@selector(didSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [bottomBarView addSubview:movieSlider];
    
    //全屏按钮
    fullScreenBtn = [[UIButton alloc] init];
    [fullScreenBtn setTitle:@"全屏" forState:UIControlStateNormal];
    [fullScreenBtn addTarget:self action:@selector(didFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:fullScreenBtn];
}


//设置控件的布局
-(void)setControlsLayout
{
    [controlsView  setFrame:self.bounds];
    
    [topBarView setFrame:CGRectMake(0, 0, FRAME_WIDTH, TOP_BAR_HEIGHT)];
    [bottomBarView setFrame:CGRectMake(0, FRAME_HEIGHT - BOTTOM_BAR_HEIGHT, FRAME_WIDTH, BOTTOM_BAR_HEIGHT)];
    
    //播放、暂停、重放
    CGFloat playControlWidth = STATE_IMAGE_WIDTH;
    CGFloat playControlHeight = STATE_IMAGE_WIDTH;
    CGFloat playControlX = (FRAME_WIDTH - playControlWidth) / 2;
    CGFloat playControlY = (FRAME_HEIGHT - playControlHeight) / 2;
    [stateControlBtn setFrame:CGRectMake(playControlX, playControlY, playControlWidth, playControlHeight)];
    
    //视频总时间和已播放时间
    CGFloat marginX = 10;
    CGFloat marginY = (BOTTOM_BAR_HEIGHT - BOTTOM_CONTROL_HEIGHT) / 2;
    CGFloat labelWidth = 80;
    CGFloat sliderWidth = FRAME_WIDTH - (marginX + labelWidth) * 2 - FULL_SCREEN_WIDTH;
    [playDurationLabel  setFrame:CGRectMake(marginX,
                                            marginY,
                                            labelWidth,
                                            BOTTOM_CONTROL_HEIGHT)];
    [durationLabel setFrame:CGRectMake(marginX + labelWidth + sliderWidth,
                                       marginY,
                                       labelWidth,
                                       BOTTOM_CONTROL_HEIGHT)];
    //滑动条
    [movieSlider setFrame:CGRectMake(marginX + labelWidth,
                                     marginY,
                                     sliderWidth,
                                     BOTTOM_CONTROL_HEIGHT)];
    
    //全屏按钮
    [fullScreenBtn setFrame:CGRectMake(FRAME_WIDTH - FULL_SCREEN_WIDTH - 10, marginY, FULL_SCREEN_WIDTH, FULL_SCREEN_HEIGHT)];
}


-(void)updateLayerFrame
{
    [self playerLayer].frame = self.layer.bounds;
}


#pragma mark - controls actions
-(void)didStateControl:(id)sender
{
    
}

-(void)didSliderValueChange:(id)sender
{

}

-(void)didFullScreen:(id)sender
{

}


#pragma mark - state control methods
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (player.status == AVPlayerStatusReadyToPlay) {
        [self setPlayer:player];
        [player play];
    }
}

@end
