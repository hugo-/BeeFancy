//
//	 ______    ______    ______
//	/\  __ \  /\  ___\  /\  ___\
//	\ \  __<  \ \  __\_ \ \  __\_
//	 \ \_____\ \ \_____\ \ \_____\
//	  \/_____/  \/_____/  \/_____/
//
//	Copyright (c) 2012 BEE creators
//	http://www.whatsbug.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//
//
//  Bee_UITipsView.m
//

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

#import <QuartzCore/QuartzCore.h>
#import "Bee_UITipsView.h"
#import "Bee_UIKeyboard.h"
#import "UIView+BeeExtension.h"
#import "UIImage+BeeExtension.h"
#import "NSObject+BeeNotification.h"
#import "UIView+BeeUISignal.h"

#define	DEFAULT_TIPS_BUBBLE_WIDTH		(160.0f)
#define	DEFAULT_TIPS_BUBBLE_HEIGHT		(140.0f)
#define DEFAULT_TIMEOUT_SECONDS			(1.0f)
#define ANIMATION_DURATION				(0.3f)

#pragma mark -

@implementation NSObject(BeeUITipsView)

- (BeeUITipsView *)presentingTips
{
	return [BeeUITipsCenter sharedInstance].tipsAppear;
}

- (BeeUITipsView *)presentMessageTips:(NSString *)message
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}

	return [[BeeUITipsCenter sharedInstance] presentMessageTips:message inView:container];
}

- (BeeUITipsView *)presentSuccessTips:(NSString *)message
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}
	
	return [[BeeUITipsCenter sharedInstance] presentSuccessTips:message inView:container];
}

- (BeeUITipsView *)presentFailureTips:(NSString *)message
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}
	
	return [[BeeUITipsCenter sharedInstance] presentFailureTips:message inView:container];
}

- (BeeUITipsView *)presentLoadingTips:(NSString *)message
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}
	
	return [[BeeUITipsCenter sharedInstance] presentLoadingTips:message inView:container];	
}

- (BeeUITipsView *)presentProgressTips:(NSString *)message
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}
	
	return [[BeeUITipsCenter sharedInstance] presentProgressTips:message inView:container];
}

- (void)dismissTips
{
	UIView * container = nil;
	
	if ( [self isKindOfClass:[UIView class]] )
	{
		container = (UIView *)self;
	}
	else if ( [self isKindOfClass:[UIViewController class]] )
	{
		container = ((UIViewController *)self).view;
	}

	return [[BeeUITipsCenter sharedInstance] dismissTipsByOwner:container];
}

@end

#pragma mark -

@interface BeeUITipsCenter(Private)
- (void)presentTips:(BeeUITipsView *)tips inView:(UIView *)view;
- (void)dismissTips;
- (void)dismissTipsByOwner:(UIView *)parentView;
- (void)dismissTipsLoading;
- (void)performDismissTips;
- (void)didAppearingAnimationDone;
- (void)didDisappearingAnimationDone;
- (void)bounce1ForAppearingAnimationStopped;
- (void)bounce2ForAppearingAnimationStopped;
@end

@interface BeeUITipsView(Private)
- (void)didTimeout;
- (void)internalWillAppear;
- (void)internalDidAppear;
- (void)internalWillDisappear;
- (void)internalDidDisappear;
- (void)internalRelayout:(UIView *)parentView;
@end

#pragma mark -

@implementation BeeUITipsCenter

DEF_SINGLETON( BeeUITipsCenter )

@synthesize defaultContainerView = _defaultContainerView;

@synthesize maskView = _maskView;
@synthesize	tipsAppear = _tipsAppear;
@synthesize	tipsDisappear = _tipsDisappear;

@synthesize bubble = _bubble;
@synthesize messageIcon = _messageIcon;
@synthesize successIcon = _successIcon;
@synthesize failureIcon = _failureIcon;

+ (void)setDefaultContainerView:(UIView *)view
{
	[BeeUITipsCenter sharedInstance].defaultContainerView = view;
}

+ (void)setDefaultMessageIcon:(UIImage *)image
{
	[BeeUITipsCenter sharedInstance].messageIcon = image;
}

+ (void)setDefaultSuccessIcon:(UIImage *)image
{
	[BeeUITipsCenter sharedInstance].successIcon = image;
}

+ (void)setDefaultFailureIcon:(UIImage *)image
{
	[BeeUITipsCenter sharedInstance].failureIcon = image;
}

+ (void)setDefaultBubble:(UIImage *)image
{
	[BeeUITipsCenter sharedInstance].bubble = image;
}

- (id)init
{
	self = [super init];
	if ( self )
	{
		_defaultContainerView = nil;
		_tipsAppear = nil;
		_tipsDisappear = nil;

		_maskView = [[UIButton alloc] initWithFrame:[UIScreen mainScreen].bounds];
		_maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.05f];
		
		[self observeNotification:BeeUIKeyboard.SHOWN];
		[self observeNotification:BeeUIKeyboard.HIDDEN];
		[self observeNotification:BeeUIKeyboard.HEIGHT_CHANGED];
	}
	
	return self;
}

- (void)dealloc
{
	[self unobserveAllNotifications];
	
	[_tipsAppear release];
	[_tipsDisappear release];
	
	[_bubble release];
	[_messageIcon release];
	[_failureIcon release];
	[_successIcon release];

	[super dealloc];
}

- (void)handleNotification:(NSNotification *)notification
{
	if ( [notification is:BeeUIKeyboard.SHOWN] || [notification is:BeeUIKeyboard.HEIGHT_CHANGED] )
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
		[_tipsAppear internalRelayout:_tipsAppear.superview];
		[_tipsDisappear internalRelayout:_tipsDisappear.superview];
		[UIView commitAnimations];
	}
	else if ( [notification is:BeeUIKeyboard.HIDDEN] )
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2f];
		[_tipsAppear internalRelayout:_tipsAppear.superview];
		[_tipsDisappear internalRelayout:_tipsDisappear.superview];
		[UIView commitAnimations];
	}
}

- (void)presentTipsView:(BeeUITipsView *)tips inView:(UIView *)view
{
	if ( nil != _tipsAppear )
	{
		if ( tips == _tipsAppear )
			return;

		if ( NO == _tipsAppear.interrupt )
			return;		
	}
	
	if ( nil == view )
	{
		view = _defaultContainerView;

		if ( nil == view )
		{
			view = [UIApplication sharedApplication].keyWindow;
		}
	}
	
	[tips internalRelayout:view];

	tips.backgroundColor = [UIColor clearColor];
	
	self.tipsDisappear = self.tipsAppear;
	self.tipsAppear = tips;
	
	[_maskView removeFromSuperview];
	[view addSubview:_maskView];
	[view bringSubviewToFront:_maskView];

	_maskView.frame = view.bounds;

	[view addSubview:_tipsAppear];
	[view bringSubviewToFront:_tipsAppear];

// animation 1
	
	_tipsAppear.alpha = 0.0f;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:ANIMATION_DURATION];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(didAppearingAnimationDone)];

	_tipsAppear.alpha = 1.0f;
	_tipsDisappear.alpha = 0.0f;
	_maskView.alpha = _tipsAppear.useMask ? 1.0f : 0.0f;

	[UIView commitAnimations];

// animation 2
	
	if ( _tipsAppear.useScaling )
	{
		_tipsAppear.transform = CGAffineTransformMakeScale( 1.2f, 1.2f );
		
		[UIView beginAnimations:nil context:NULL];		
		[UIView setAnimationDuration:ANIMATION_DURATION];
		[UIView setAnimationBeginsFromCurrentState:YES];
		
		_tipsAppear.transform = CGAffineTransformMakeScale( 1.0f, 1.0f );
		_tipsDisappear.transform = CGAffineTransformMakeScale( 0.8f, 0.8f );

		[UIView commitAnimations];
	}
	
// animation 3

	if ( _tipsAppear.useBounces )
	{
		_tipsAppear.transform = CGAffineTransformScale( CGAffineTransformIdentity, 0.001, 0.001 );

		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:(ANIMATION_DURATION / 1.5)];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(bounce1ForAppearingAnimationStopped)];
	
		_tipsAppear.transform = CGAffineTransformScale( CGAffineTransformIdentity, 1.1f, 1.1f );
	
		[UIView commitAnimations];	
	}

	[_tipsAppear internalWillAppear];
	[_tipsDisappear internalWillDisappear];
}

- (void)didAppearingAnimationDone
{
	if ( NO == _tipsAppear.useMask )
	{
		_maskView.alpha = 0.0f;
		[_maskView removeFromSuperview];
	}

	[_tipsDisappear removeFromSuperview];
	_tipsDisappear = nil;
	
	[_tipsAppear internalDidAppear];
	[_tipsDisappear internalDidDisappear];
}

- (void)bounce1ForAppearingAnimationStopped
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:(ANIMATION_DURATION / 2.0f)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2ForAppearingAnimationStopped)];
	
	_tipsAppear.transform = CGAffineTransformScale( CGAffineTransformIdentity, 0.9, 0.9 );
	
	[UIView commitAnimations];
}

- (void)bounce2ForAppearingAnimationStopped
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:(ANIMATION_DURATION / 2.0f)];
	
	_tipsAppear.transform = CGAffineTransformIdentity;
	
	[UIView commitAnimations];
}

- (void)dismissTips
{
	[self performDismissTips];
}

- (void)dismissTipsByOwner:(UIView *)parentView
{
	if ( _tipsAppear && _tipsAppear.superview == parentView )
	{
		[self performDismissTips];
	}
}

- (void)performDismissTips
{
	if ( nil == _tipsAppear )
		return;

	self.tipsDisappear = self.tipsAppear;
	self.tipsAppear = nil;

	[UIView beginAnimations:nil context:NULL];		
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(didDisappearingAnimationDone)];

	_tipsDisappear.alpha = 0.0f;

	if ( _tipsDisappear.useScaling )
	{
		_tipsDisappear.transform = CGAffineTransformMakeScale( 0.8f, 0.8f );
	}

	_maskView.alpha = 0.0f;
	
	[UIView commitAnimations];
	
	[_tipsAppear internalWillAppear];
	[_tipsDisappear internalWillDisappear];
}

- (void)didDisappearingAnimationDone
{
	if ( NO == _tipsAppear.useMask )
	{
		_maskView.alpha = 0.0f;
		[_maskView removeFromSuperview];
	}
	
	[_tipsDisappear removeFromSuperview];
	_tipsDisappear = nil;
	
	[_tipsAppear internalDidAppear];
	[_tipsDisappear internalDidDisappear];
}

- (BeeUITipsView *)presentMessageTips:(NSString *)message inView:(UIView *)view
{
	BeeUIMessageTipsView * tips = [[BeeUIMessageTipsView alloc] init];
	tips.iconView.image = _messageIcon;
	tips.labelView.text = message;
	[tips presentInView:view];
	return [tips autorelease];
}

- (BeeUITipsView *)presentSuccessTips:(NSString *)message inView:(UIView *)view
{
	BeeUIMessageTipsView * tips = [[BeeUIMessageTipsView alloc] init];
	tips.iconView.image = _successIcon;
	tips.labelView.text = message;
	[tips presentInView:view];
	return [tips autorelease];
}

- (BeeUITipsView *)presentFailureTips:(NSString *)message inView:(UIView *)view
{
	BeeUIMessageTipsView * tips = [[BeeUIMessageTipsView alloc] init];
	tips.iconView.image = _failureIcon;
	tips.labelView.text = message;
	[tips presentInView:view];
	return [tips autorelease];
}

- (BeeUITipsView *)presentLoadingTips:(NSString *)message inView:(UIView *)view
{
	BeeUILoadingTipsView * tips = [[BeeUILoadingTipsView alloc] init];
	tips.labelView.text = message;
	[tips presentInView:view];
	[tips.indicator startAnimating];
	return [tips autorelease];
}

- (BeeUITipsView *)presentProgressTips:(NSString *)message inView:(UIView *)view
{
	BeeUIProgressTipsView * tips = [[BeeUIProgressTipsView alloc] init];
	tips.labelView.text = message;
	[tips presentInView:view];
	[tips updateProgress:0.0f];
	return [tips autorelease];
}

@end

#pragma mark -

@implementation BeeUITipsView

@synthesize timerSeconds = _timerSeconds;

@synthesize useMask = _useMask;
@synthesize useScaling = _useScaling;
@synthesize useBounces = _useBounces;
@synthesize interrupt = _interrupt;
@synthesize timeLimit = _timeLimit;
@synthesize exclusive = _exclusive;
@synthesize fullScreen = _fullScreen;

DEF_SIGNAL( WILL_APPEAR );
DEF_SIGNAL( DID_APPEAR );
DEF_SIGNAL( WILL_DISAPPEAR );
DEF_SIGNAL( DID_DISAPPEAR );

- (id)init
{
	self = [super initWithFrame:CGRectZero];
	if ( self )
	{
		self.backgroundColor = [UIColor clearColor];
		self.timerSeconds = DEFAULT_TIMEOUT_SECONDS;
		self.timeLimit = YES;
		self.interrupt = YES;
		self.fullScreen = NO;
//		self.useScaling = YES;
//		self.useBounces = YES;
	}
	
	return self;
}

- (void)dealloc
{	
	[_timer invalidate];
	_timer = nil;

	[super dealloc];
}

- (void)internalWillAppear
{	
	[_timer invalidate];
	_timer = nil;

	[self sendUISignal:BeeUITipsView.WILL_APPEAR];
}

- (void)internalDidAppear
{	
	[_timer invalidate];
	_timer = nil;

	if ( _timeLimit )
	{
		_timer = [NSTimer scheduledTimerWithTimeInterval:self.timerSeconds
												  target:self
												selector:@selector(dismiss)
												userInfo:nil
												 repeats:NO];
	}	

	[self sendUISignal:BeeUITipsView.DID_APPEAR];
}

- (void)internalWillDisappear
{
	[_timer invalidate];
	_timer = nil;
	
	[self sendUISignal:BeeUITipsView.WILL_DISAPPEAR];
}

- (void)internalDidDisappear
{
	[self sendUISignal:BeeUITipsView.DID_DISAPPEAR];
}

- (void)internalRelayout:(UIView *)parentView
{
	if ( _fullScreen )
	{
		self.frame = parentView.bounds;
	}
	else
	{
		CGRect bound = parentView.bounds;

		if ( [BeeUIKeyboard sharedInstance].shown )
		{
			bound.size.height -= [BeeUIKeyboard sharedInstance].height;
		}

//		bound.origin.y += 44.0f;
		bound.size.height -= 44.0f;
		bound.size.height -= 20.0f;

		CGRect viewFrame;
		viewFrame.origin.x = bound.origin.x + (bound.size.width - DEFAULT_TIPS_BUBBLE_WIDTH) / 2.0f;
		viewFrame.origin.y = bound.origin.y + (bound.size.height - DEFAULT_TIPS_BUBBLE_HEIGHT) / 2.0f;
		viewFrame.size.width = DEFAULT_TIPS_BUBBLE_WIDTH;
		viewFrame.size.height = DEFAULT_TIPS_BUBBLE_HEIGHT;

		self.frame = viewFrame;
	}
}

- (void)presentInView:(UIView *)view
{
	[[BeeUITipsCenter sharedInstance] presentTipsView:self inView:view];
}

- (void)present
{
	[[BeeUITipsCenter sharedInstance] presentTipsView:self inView:nil];
}

- (void)dismiss
{
	[_timer invalidate];
	_timer = nil;

	[[BeeUITipsCenter sharedInstance] dismissTips];
}

@end

#pragma mark -

@implementation BeeUIMessageTipsView

@synthesize bubbleView = _bubbleView;
@synthesize iconView = _iconView;
@synthesize labelView = _labelView;

- (id)init
{
	self = [super init];
	if ( self )
	{
		self.useMask = YES;
		self.interrupt = YES;
		self.exclusive = NO;
		self.timeLimit = YES;
		self.timerSeconds = DEFAULT_TIMEOUT_SECONDS;

		_bubbleView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_bubbleView.backgroundColor = [UIColor clearColor];
		_bubbleView.contentMode = UIViewContentModeCenter;
		_bubbleView.image = [BeeUITipsCenter sharedInstance].bubble.stretched;
		[self addSubview:_bubbleView];

		_iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_iconView.backgroundColor = [UIColor clearColor];
		_iconView.contentMode = UIViewContentModeCenter;
		[self addSubview:_iconView];

		_labelView = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelView.font = [UIFont boldSystemFontOfSize:14.0f];
        _labelView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _labelView.textAlignment = UITextAlignmentCenter;
		_labelView.textColor = [UIColor whiteColor];
        _labelView.backgroundColor = [UIColor clearColor];
        _labelView.lineBreakMode = UILineBreakModeClip;
		_labelView.numberOfLines = 2;
        [self addSubview:_labelView];
	}
	
	return self;
}

- (void)dealloc
{
	SAFE_RELEASE_SUBVIEW( _bubbleView );
	SAFE_RELEASE_SUBVIEW( _iconView );
	SAFE_RELEASE_SUBVIEW( _labelView );

	[super dealloc];
}

- (void)internalRelayout:(UIView *)parentView
{
	[super internalRelayout:parentView];

	_bubbleView.frame = self.bounds;
	
	if ( _iconView.image )
	{
		CGRect iconFrame = self.bounds;
		iconFrame.size.height -= 20.0f;
		_iconView.frame = iconFrame;

		CGRect labelFrame;
		labelFrame.size.width = self.bounds.size.width;
		labelFrame.size.height = 60.0f;
		labelFrame.origin.x = 0.0f;
		labelFrame.origin.y = self.bounds.size.height - labelFrame.size.height;
		_labelView.frame = CGRectInset(labelFrame, 5.0f, 0.0f);
	}
	else
	{
		_labelView.frame = CGRectInset(self.bounds, 5.0f, 0.0f);
	}	
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	[self dismiss];
}

@end

#pragma mark -

@implementation BeeUILoadingTipsView

@synthesize bubbleView = _bubbleView;
@synthesize labelView = _labelView;
@synthesize indicator = _indicator;

- (id)init
{
	self = [super init];
	if ( self )
	{
		self.useMask = YES;
		self.interrupt = NO;
		self.exclusive = YES;
		self.timeLimit = NO;

		_bubbleView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_bubbleView.backgroundColor = [UIColor clearColor];
		_bubbleView.contentMode = UIViewContentModeCenter;
		_bubbleView.image = [BeeUITipsCenter sharedInstance].bubble.stretched;
		[self addSubview:_bubbleView];
		
		_indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		_indicator.backgroundColor = [UIColor clearColor];
		[self addSubview:_indicator];

		_labelView = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelView.font = [UIFont boldSystemFontOfSize:14.0f];
        _labelView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _labelView.textAlignment = UITextAlignmentCenter;
		_labelView.textColor = [UIColor whiteColor];
        _labelView.backgroundColor = [UIColor clearColor];
        _labelView.lineBreakMode = UILineBreakModeClip;
        _labelView.numberOfLines = 2;
        [self addSubview:_labelView];
	}

	return self;
}

- (void)dealloc
{
	SAFE_RELEASE_SUBVIEW( _bubbleView );
	SAFE_RELEASE_SUBVIEW( _indicator );
	SAFE_RELEASE_SUBVIEW( _labelView );

	[super dealloc];
}

- (void)internalRelayout:(UIView *)parentView
{
	[super internalRelayout:parentView];

	_bubbleView.frame = self.bounds;
	
	CGRect indicatorFrame;
	indicatorFrame.size.width = 14.0f;
	indicatorFrame.size.height = 14.0f;
	indicatorFrame.origin.x = (self.bounds.size.width - indicatorFrame.size.width) / 2.0f;
	indicatorFrame.origin.y = (self.bounds.size.height - indicatorFrame.size.height) / 2.0f;
	_indicator.frame = indicatorFrame;

	CGRect labelFrame;
	labelFrame.size.width = self.bounds.size.width;
	labelFrame.size.height = 60.0f;
	labelFrame.origin.x = 0.0f;
	labelFrame.origin.y = self.bounds.size.height - labelFrame.size.height;
	_labelView.frame = CGRectInset(labelFrame, 5.0f, 0.0f);	
}

@end

#pragma mark -

@implementation BeeUIProgressTipsView

@synthesize bubbleView = _bubbleView;
@synthesize indicator = _indicator;
@synthesize labelView = _labelView;

- (id)init
{
	self = [super init];
	if ( self )
	{
		self.useMask = YES;
		self.interrupt = NO;
		self.exclusive = YES;
		self.timeLimit = NO;

		_bubbleView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_bubbleView.backgroundColor = [UIColor clearColor];
		_bubbleView.contentMode = UIViewContentModeCenter;
		_bubbleView.image = [BeeUITipsCenter sharedInstance].bubble.stretched;
		[self addSubview:_bubbleView];
		
		_indicator = [[UIProgressView alloc] initWithFrame:CGRectZero];
		_indicator.backgroundColor = [UIColor clearColor];
		[self addSubview:_indicator];

		_labelView = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelView.font = [UIFont boldSystemFontOfSize:14.0f];
        _labelView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _labelView.textAlignment = UITextAlignmentCenter;
		_labelView.textColor = [UIColor whiteColor];
        _labelView.backgroundColor = [UIColor clearColor];
        _labelView.lineBreakMode = UILineBreakModeClip;
        _labelView.numberOfLines = 2;
        [self addSubview:_labelView];
	}
	
	return self;
}

- (void)dealloc
{
	SAFE_RELEASE_SUBVIEW( _bubbleView );
	SAFE_RELEASE_SUBVIEW( _indicator );
	SAFE_RELEASE_SUBVIEW( _labelView );

	[super dealloc];
}

- (void)updateProgress:(float)p
{
	if ( p <= 0.0f )
	{
		_indicator.hidden = YES;
	}
	else
	{
		_indicator.hidden = NO;
	}
	
	_indicator.progress = p;;
}

- (void)internalRelayout:(UIView *)parentView
{
	[super internalRelayout:parentView];

	_bubbleView.frame = self.bounds;
	
	CGRect indicatorRect;
	indicatorRect.size.width = self.bounds.size.width - 40.0f;
	indicatorRect.size.height = 20.0f;
	indicatorRect.origin.x = (self.bounds.size.width - indicatorRect.size.width) / 2.0f;
	indicatorRect.origin.y = (self.bounds.size.height - 20.0f - 20.0f) / 2.0f;
	_indicator.frame = indicatorRect;

	CGRect labelFrame;
	labelFrame.size.width = self.bounds.size.width;
	labelFrame.size.height = 60.0f;
	labelFrame.origin.x = 0.0f;
	labelFrame.origin.y = self.bounds.size.height - labelFrame.size.height;
	_labelView.frame = CGRectInset(labelFrame, 5.0f, 0.0f);	
}

@end

#endif	// #if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
