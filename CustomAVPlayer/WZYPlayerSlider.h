//
//  WZYPlayerSlider.h
//  WZYPlayerSlider
//
//  Copyright (c) 2013 makoto_kw. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WZYPlayerSliderPopover;

@interface WZYPlayerSlider : UISlider

@property(nonatomic,getter=isPopoverEnabled) BOOL popoverEnabled;
@property(nonatomic) WZYPlayerSliderPopover *popover;
@property(nonatomic,assign) NSTimeInterval popoverAnimationDuration;

@property(nonatomic,assign) NSTimeInterval duration;
@property(nonatomic,assign) NSTimeInterval availableDuration;

- (void)setAvailableTrackImage:(UIImage *)image;

@end
