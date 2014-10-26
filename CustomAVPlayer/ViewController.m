//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by ChengZhifeng on 14-10-26.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import "ViewController.h"
#import "CustomMoviePlayer.h"

@interface ViewController (){
    CustomMoviePlayer *playerView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray  *nibArray= [[NSBundle mainBundle] loadNibNamed:@"CustomMoviePlayer" owner:nil options:nil];
    playerView=(CustomMoviePlayer *)[nibArray firstObject];
    
    [self.view addSubview:playerView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [playerView setFrame:self.view.bounds];
    [playerView updateLayerFrame];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
