//
//  WZYPlayerSlider.m
//  WZYPlayerSlider
//
//  Copyright (c) 2013 makoto_kw. All rights reserved.
//

#import "WZYPlayerSlider.h"
#import "WZYPlayerSliderPopover.h"

@implementation WZYPlayerSlider

{
    NSTimeInterval _availableDuration;
    UIView *_maximumTrackView;
    UIImageView *_availableTrack;
    UIImage *_maximumTrackImage;
    UIImage *_minmumTrackImage;
    BOOL _availableTrackAdded;
    CGRect _trackRect;
}

@synthesize popoverEnabled = _popoverEnabled;
@synthesize popover = _popover;
@synthesize popoverAnimationDuration = _popoverAnimationDuration;
@synthesize duration = _duration;
@dynamic availableDuration;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    _popover = [[WZYPlayerSliderPopover alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y - 32, 60, 32)];
    _popover.alpha = 0;
    _popoverAnimationDuration = 0.25f;
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [self addGestureRecognizer:gr];
    
    [self.superview addSubview:_popover];
    [self addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
    
    UIImageView *availableTrack = [[UIImageView alloc] initWithImage:nil];
    _availableTrack = availableTrack;
    
    [self loadSliderResources];
}

- (UIView *)findMaxinumTrackView:(UIView *)containerView
{
    for (UIView *view in containerView.subviews) {
        if ([view isMemberOfClass:[UIView class]]) {
            UIView *trackView = [self findMaxinumTrackView:view];
            if (trackView) {
                return view; // return parent
            }
            continue;
        }
        if ([view isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)view;
            if (imageView.image == _maximumTrackImage) {
                return view;
            }
        }
    }
    return nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_availableTrackAdded) {
        UIView *trackView = [self findMaxinumTrackView:self];
        [self insertSubview:_availableTrack aboveSubview:trackView];
    }
}

- (void)loadSliderResources
{
    UIImage *thumbImage = [UIImage imageNamed:@"WZYPlayerSliderResources.bundle/thumbImage"];
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    
    _minmumTrackImage = [[UIImage imageNamed:@"WZYPlayerSliderResources.bundle/minimumTrackImage.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 3, 1, 1)];
    _maximumTrackImage = [[UIImage imageNamed:@"WZYPlayerSliderResources.bundle/maximumTrackImage.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 3, 1, 1)];
    [self setMinimumTrackImage:_minmumTrackImage forState:UIControlStateNormal];
    [self setMaximumTrackImage:_maximumTrackImage forState:UIControlStateNormal];

    UIImage *availableTrackImage = [[UIImage imageNamed:@"WZYPlayerSliderResources.bundle/availableTrackImage.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    [self setAvailableTrackImage:availableTrackImage];
}

- (void)setAvailableTrackImage:(UIImage *)image
{
    _availableTrack.image = image;
}

- (double)availableDuration
{
    return _availableDuration;
}

- (void)setAvailableDuration:(NSTimeInterval)availableDuration
{
    if (_availableDuration != availableDuration) {
        _availableDuration = availableDuration;
        [self updateAvailableTrackView];
    }
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect trackRect = [super trackRectForBounds:bounds];
    _trackRect = trackRect;
    [self updateAvailableTrackView];
    return trackRect;
}

- (void)updateAvailableTrackView
{
    float progress = (_duration > 0) ? _availableDuration / _duration : 0.0f;
    if (progress < 0.0) progress = 0.0;
    else if (progress > 1.0) progress = 1.0;
    CGRect availableTrackRect = CGRectMake(_trackRect.origin.x,
                                           _trackRect.origin.y,
                                           _trackRect.size.width * progress,
                                           _trackRect.size.height);
    _availableTrack.frame = availableTrackRect;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)sliderTapped:(UIGestureRecognizer *)gesture
{    
    UISlider *slider = (UISlider*)gesture.view;
    if (slider.highlighted) {
        return;
    }
    CGPoint pt = [gesture locationInView:slider];
    CGFloat percentage = pt.x / slider.bounds.size.width;
    CGFloat delta = percentage * (slider.maximumValue - slider.minimumValue);
    CGFloat value = slider.minimumValue + delta;
    slider.value = value;
}

+ (NSString *)formatPlayTimeFromInterval:(NSTimeInterval)interval
{
    NSTimeInterval sec = abs(interval);
    NSUInteger hour = (NSUInteger)sec/3600;
    sec -= hour*3600;
    NSUInteger min  = (NSUInteger)sec/60;
    sec -= min*60;
    
    NSString *prefix = ( interval < 0  ) ? @"-" : @"";
    if (hour >= 1) {
        return [prefix stringByAppendingFormat:@"%d:%02d:%02d", hour, min, (int)sec];
    }
    return [prefix stringByAppendingFormat:@"%d:%02d", min, (int)sec];
}

- (void)valueChanged
{
    [self updatePopover];
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self updatePopover];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_popoverEnabled) {
        [self updatePopover];
        [self showPopoverAnimated:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hidePopoverAnimated:YES];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hidePopoverAnimated:YES];
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark -
#pragma mark - Popover methods

- (void)updatePopover
{
    if (_popoverEnabled) {
        [self updatePopoverFrame];
        [self updatePopoverPlayTime];
    }    
}

- (void)updatePopoverFrame
{
    CGFloat minimum =  self.minimumValue;
	CGFloat maximum = self.maximumValue;
	CGFloat value = self.value;
	
	if (minimum < 0.0) {
		value = self.value - minimum;
		maximum = maximum - minimum;
		minimum = 0.0;
	}
	
	CGFloat x = self.frame.origin.x;
    CGFloat maxMin = (maximum + minimum) / 2.0;
    
    x += (((value - minimum) / (maximum - minimum)) * self.frame.size.width) - (_popover.frame.size.width / 2.0);
	
	if (value > maxMin) {
		value = (value - maxMin) + (minimum * 1.0);
		value = value / maxMin;
		value = value * 11.0;
		x = x - value;
	} else {
		value = (maxMin - value) + (minimum * 1.0);
		value = value / maxMin;
		value = value * 11.0;
		x = x + value;
	}
    
    CGRect popoverRect = _popover.frame;
    popoverRect.origin.x = x;
    popoverRect.origin.y = self.frame.origin.y - popoverRect.size.height - 1;
    
    NSTimeInterval playTime = _duration * self.value;
    if (playTime > 3600) {
        popoverRect.size.width = (CGFloat)60;
    } else if (playTime > 60) {
        popoverRect.size.width = (CGFloat)50;
    } else {
        popoverRect.size.width = (CGFloat)40;
    }
    
    _popover.frame = popoverRect;
}

- (void)updatePopoverPlayTime
{
    _popover.textLabel.text = [WZYPlayerSlider formatPlayTimeFromInterval:_duration * self.value];
}

- (void)showPopoverAnimated:(BOOL)animated
{
    if (animated && _popoverAnimationDuration > 0) {
        [UIView animateWithDuration:_popoverAnimationDuration animations:^{
            _popover.alpha = 1.0;
        }];
    } else {
        _popover.alpha = 1.0;
    }
}

- (void)hidePopoverAnimated:(BOOL)animated
{
    if (animated && _popoverAnimationDuration > 0) {
        [UIView animateWithDuration:_popoverAnimationDuration animations:^{
            _popover.alpha = 0;
        }];
    } else {
        _popover.alpha = 0;
    }
}

@end
