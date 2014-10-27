//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by ChengZhifeng on 14-10-26.
//  Copyright (c) 2014年 ChengZhifeng. All rights reserved.
//

#import "ViewController.h"
#import "CustomMoviePlayer.h"

@interface ViewController ()<CustomMoviePlayerDelegate>
{

}

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player1.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)pulldown:(CustomMoviePlayer *)customMoviePlayer
{
    NSLog(@"pull down");
}


-(void)snsShare:(CustomMoviePlayer *)customMoviePlayer
{
    NSLog(@"sns share");
}


@end
