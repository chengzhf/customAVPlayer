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
#import <SDWebImage/SDWebImageManager.h>


@interface CustomMoviePlayer()
{
    AVPlayerItem *playerItem;

    BOOL isShowingControls;
    BOOL isFullScreen;
    CGRect normalFrame; //非全屏的frame
    NSTimer *hideControlsTimer;
    
    //视频概要图
    UIImageView *preImageView;
    
    //更多功能层
    UIView *controlsView;
    
    //更多功能层里面的底部bar
    UIView *bottomBarView;
    //更多功能层里面的顶部bar
    UIView *topBarView;
    
    //下拉按钮
    UIButton *dragDownBtn;
    //分享按钮
    UIButton *snsShareBtn;
    
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

@synthesize player,videoState,delegate;

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
    
    playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.videoURL]];
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
#warning 这种方式不完全保险，如果默认大小就是全屏的则无法判断
    //非全屏时就要记录原来的frame
    UIWindow *w = [[UIApplication sharedApplication].delegate window];
    CGFloat wHeight = w.bounds.size.height;
    CGFloat wWidth = w.bounds.size.width;
    if (self.frame.size.width<wWidth || self.frame.size.height<wHeight) {
        normalFrame = self.frame;
    }
    
    //旋转的时候会退出全屏，所以这时候要重新进入一次全屏
    if (isFullScreen) {
        [self enterFullScreen];
    }
    [self setControlsLayout];
}

-(void)initParameters
{
    videoState = VIDEO_PLAYING;
    isShowingControls = YES;
    
    //测试数据
    self.videoURL = @"http://fkzt.nos.netease.com/ios_sample1.mp4";
    //NSString *movieURL = @"http://www.jxvdy.com/file/upload/201309/18/18-10-03-19-3.mp4";
}

-(void)initGestures
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tapGesture];
}

//初始化控件
-(void)initCustomControls
{
    preImageView = [[UIImageView alloc] init];
    [preImageView setContentMode:UIViewContentModeScaleAspectFit];
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.previewImageURL] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        [preImageView setImage:image];
    }];
    [self addSubview:preImageView];
    
    controlsView = [[UIView alloc] init];
    [self addSubview:controlsView];
    
    topBarView = [[UIView alloc] init];
    bottomBarView = [[UIView alloc] init];
    
    [bottomBarView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]];
    [controlsView addSubview:topBarView];
    [controlsView addSubview:bottomBarView];
    
    //下拉按钮
    dragDownBtn = [[UIButton alloc] init];
    [dragDownBtn setBackgroundImage:[UIImage imageNamed:@"pulldown"] forState:UIControlStateNormal];
    [dragDownBtn addTarget:self action:@selector(didPullDown:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:dragDownBtn];
    
    
    //分享按钮
    snsShareBtn = [[UIButton alloc] init];
    [snsShareBtn setBackgroundImage:[UIImage imageNamed:@"snsShare"] forState:UIControlStateNormal];
    [snsShareBtn addTarget:self action:@selector(didSNSShare:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:snsShareBtn];
    

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
    movieSlider.maximumValue = 0.0f;
    movieSlider.duration = 0.0f;
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
    [preImageView setFrame:self.bounds];
    [controlsView  setFrame:self.bounds];
    
    [topBarView setFrame:CGRectMake(0, 0, FRAME_WIDTH, TOP_BAR_HEIGHT)];
    [bottomBarView setFrame:CGRectMake(0, FRAME_HEIGHT - BOTTOM_BAR_HEIGHT, FRAME_WIDTH, BOTTOM_BAR_HEIGHT)];
    
    //下拉按钮
    [dragDownBtn setFrame:CGRectMake(8, (TOP_BAR_HEIGHT - SHARE_BTN_WIDTH)/2, SHARE_BTN_WIDTH, SHARE_BTN_WIDTH)];
    
    //分享按钮
    [snsShareBtn setFrame:CGRectMake(FRAME_WIDTH - SHARE_BTN_WIDTH - 8, (TOP_BAR_HEIGHT - SHARE_BTN_WIDTH)/2, SHARE_BTN_WIDTH, SHARE_BTN_WIDTH)];
    
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
-(void)didPullDown:(id)sender
{
    [self endTimer];
    if ([delegate respondsToSelector:@selector(pulldown:)]) {
        [delegate pulldown:self];
    }
    [self beginTimer];
}

-(void)didSNSShare:(id)sender
{
    [self endTimer];
    if ([delegate respondsToSelector:@selector(snsShare:)]) {
        [delegate snsShare:self];
    }
    [self beginTimer];
}

-(void)didStateControl:(id)sender
{
    [self endTimer];
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
    [self endTimer];
    if(isFullScreen){
        [self exitFullScreen];
    }else{
        [self enterFullScreen];
    }
}


#pragma mark - state control methods
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"status"]) {
        NSLog(@"status:%ld",(long)player.status);
        if (player.status == AVPlayerStatusReadyToPlay) {
            [preImageView setAlpha:0.0f];
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
    CMTime totalTime = player.currentItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (totalMovieDuration>0) {
        NSString *totalDurationStr = [self timeInfoFormat:totalMovieDuration];
        durationLabel.text = totalDurationStr;
        movieSlider.maximumValue = totalMovieDuration;
        movieSlider.duration = totalMovieDuration;
    }
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

-(void)enterFullScreen
{
    
    isFullScreen = YES;
    [fullScreenBtn setTitle:@"退出" forState:UIControlStateNormal];
    
    UIWindow *w = [[UIApplication sharedApplication].delegate window];
    self.frame = w.bounds;
 
    [topBarView setAlpha:0.0f];
    [self showControls];
    [self beginTimer];
}

-(void)exitFullScreen
{
    isFullScreen = NO;
    [fullScreenBtn setTitle:@"全屏" forState:UIControlStateNormal];
    
    [self printRectInfo:normalFrame];
    self.frame = normalFrame;
    
    [topBarView setAlpha:1.0f];
    [self showControls];
    [self beginTimer];
}

-(UIViewController *)getViewController
{
    id object = [self nextResponder];
    while (![object isKindOfClass:[UIViewController class]] && object != nil) {
        object = [object nextResponder];
    }
    UIViewController *uc=(UIViewController*)object;
    return uc;
}

-(void)printRectInfo:(CGRect)rect
{
    NSLog(@"rect info x:%f y:%f w:%f h:%f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}

@end
