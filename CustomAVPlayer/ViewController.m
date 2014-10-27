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
    CustomMoviePlayer *playerView2;
}

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSArray  *nibArray= [[NSBundle mainBundle] loadNibNamed:@"CustomMoviePlayer" owner:nil options:nil];
    playerView=(CustomMoviePlayer *)[nibArray firstObject];
    
    NSArray  *nibArray2= [[NSBundle mainBundle] loadNibNamed:@"CustomMoviePlayer" owner:nil options:nil];
    playerView2=(CustomMoviePlayer *)[nibArray2 firstObject];
    
    [self.view1 addSubview:playerView];
    [self.view2 addSubview:playerView2];
}

-(void)viewWillAppear:(BOOL)animated
{
    [playerView setFrame:self.view1.bounds];
    [playerView updateLayerFrame];
    
    [playerView2 setFrame:self.view2.bounds];
    [playerView2 updateLayerFrame];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
