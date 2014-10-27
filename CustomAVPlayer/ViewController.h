//
//  ViewController.h
//  CustomAVPlayer
//
//  Created by ChengZhifeng on 14-10-26.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerDemoPlaybackView.h"
#import "CustomMoviePlayer.h"

@class AVPlayer;

@interface ViewController : UIViewController



@property (weak, nonatomic) IBOutlet CustomMoviePlayer *view1;
@property (weak, nonatomic) IBOutlet CustomMoviePlayer *view2;

@end

