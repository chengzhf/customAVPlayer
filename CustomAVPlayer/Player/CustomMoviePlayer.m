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
#define HIDECONTROL_TIMER_INTERVAL 3

#import "CustomMoviePlayer.h"
#import "WZYPlayerSlider.h"
#import <MBProgressHUD/MBProgressHUD.h>


@interface CustomMoviePlayer()
{
    AVPlayerItem *playerItem;

    BOOL isShowingControls;
    NSTimer *hideControlsTimer;
    
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

@synthesize player,videoState;

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
    [self initParameters];
    [self initCustomControls];
    [self initGestures];
    
    [self showLoading];
    
//    NSString *movieURL = @"http://www.jxvdy.com/file/upload/201309/18/18-10-03-19-3.mp4";
    NSString *movieURL = @"http://fkzt.nos.netease.com/ios_sample.mp4";
    
    playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:movieURL]];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    
    //监控视频状态
    [player.currentItem addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    //监控缓冲状态
    [player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控播放进度
    [self monitorMovieProgress];
    //监控播放状态rate，播放/暂停
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    //监控播放停止状态
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
}

-(void)layoutSubviews
{
    [self setControlsLayout];
}

-(void)initParameters
{
    videoState = VIDEO_PLAYING;
    isShowingControls = YES;
}

-(void)initGestures
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tapGesture];
}

//初始化控件布局。
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
    movieSlider.minimumValue = 0.0f;
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

-(void)dealloc
{
    //释放监控
    [player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
    [player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
}

#pragma mark - controls actions
-(void)didStateControl:(id)sender
{
    if (videoState == VIDEO_PLAYING) {
        [player pause];
        [self endTimer];
    }else if(videoState == VIDEO_PAUSE){
        [player play];
        [self beginTimer];
    }else if(videoState == VIDEO_STOP){
        [self showLoading];
        CMTime beginCMTime = CMTimeMake(0, 1);
        [player seekToTime:beginCMTime completionHandler:^(BOOL finish){
            [self hideLoading];
            [player play];
            [self beginTimer];
        }];
    }else{
        [player play];
        [self beginTimer];
    }
}

-(void)didSliderValueChange:(id)sender
{

}

-(void)didFullScreen:(id)sender
{

}


#pragma mark - state control methods
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"status"]) {
        NSLog(@"status:%ld",(long)player.status);
        if (player.status == AVPlayerStatusReadyToPlay) {
            //开始播放并设置总时间
            [self setPlayer:player];
            [player play];
            [self setDuration];
            [self hideLoading];
            [self beginTimer];
        }
    }
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        float bufferTime = [self availableDuration];
        movieSlider.availableDuration = bufferTime;
    }

    if ([keyPath isEqualToString:@"rate"]) {
        if (player.rate>=1.0) {
            videoState = VIDEO_PLAYING;
            [stateControlBtn setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        }else{
            videoState = VIDEO_PAUSE;
            [self showControls];
            [stateControlBtn setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        }
    }
}

-(void)playerItemDidReachEnd:(NSNotification *)notification
{
    videoState = VIDEO_STOP;
    [self showControls];
    [stateControlBtn setBackgroundImage:[UIImage imageNamed:@"replay"] forState:UIControlStateNormal];
}

//设置视频总时间
-(void)setDuration
{
    //计算视频总时间
    CMTime totalTime = player.currentItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    NSString *totalDurationStr = [self timeInfoFormat:totalMovieDuration];
    NSLog(@"totalMovieDuration:%@",totalDurationStr);
    //在totalTimeLabel上显示总时间
    durationLabel.text = totalDurationStr;
    //设置slider
    movieSlider.maximumValue = totalMovieDuration;
    movieSlider.duration = totalMovieDuration;
}

//监控视频播放的进度
-(void)monitorMovieProgress{
    //修改slider和前面的text
    __weak CustomMoviePlayer *weakSelf = self;
    __weak AVPlayer *weakPlayer = player;
    __weak WZYPlayerSlider *weakSlider = movieSlider;
    __weak UILabel *weakCurrentimeLabel = playDurationLabel;
    [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
        //获取当前时间
        CMTime currentTime = weakPlayer.currentItem.currentTime;
        //转成秒数
        CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
        weakSlider.value = currentPlayTime;
        weakCurrentimeLabel.text = [weakSelf timeInfoFormat:currentPlayTime];
    }];
    
    //添加拖动事件
    [movieSlider addTarget:self action:@selector(scrubbingDidBegin:) forControlEvents:UIControlEventTouchDown];
    [movieSlider addTarget:self action:@selector(scrubberIsScrolling:) forControlEvents:UIControlEventValueChanged];
    [movieSlider addTarget:self action:@selector(scrubbingDidEnd:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
}

//按动滑块
-(void)scrubbingDidBegin:(id)sender
{
    [player pause];
    [self showLoading];
}

//快进
-(void)scrubberIsScrolling:(id)sender
{
    double currentTime = movieSlider.value;
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime, 1);
    [player seekToTime:dragedCMTime completionHandler:^(BOOL finish){
         if (videoState == VIDEO_PLAYING)
         {
             [player play];
         }
     }];
}

-(void)scrubbingDidEnd:(id)sender
{
    [self hideLoading];
}

#pragma mark - gesture methods
-(void)tap:(UIGestureRecognizer *)gesture
{
    if (!isShowingControls) {
        [self showControls];
        [self beginTimer];
    }else{
        [self hideControls];
        [self endTimer];
    }
}


#pragma mark - timer methods
-(void)hideControlsTimeUp:(id)sender
{
    [self hideControls];
}


#pragma mark - private methods
-(NSString *)timeInfoFormat:(CGFloat)timeNumber
{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:timeNumber];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (timeNumber/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

//获得加载进度
- (CGFloat)availableDuration
{
    NSArray *loadedTimeRanges = [[player currentItem] loadedTimeRanges];
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}

-(void)showLoading
{
    MBProgressHUD *loadingView = [[MBProgressHUD alloc] initWithView:self];
    [self addSubview:loadingView];
    [loadingView show:YES];
}

-(void)hideLoading
{
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
}

-(void)beginTimer
{
    [self endTimer];
    hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:HIDECONTROL_TIMER_INTERVAL target:self selector:@selector(hideControlsTimeUp:) userInfo:nil repeats:NO];
}

-(void)endTimer
{
    if (hideControlsTimer) {
        [hideControlsTimer invalidate];
        hideControlsTimer = nil;
    }
}

-(void)showControls
{
    controlsView.alpha = 1;
    isShowingControls = YES;
}

-(void)hideControls
{
    controlsView.alpha = 0;
    isShowingControls = NO;
}

@end
