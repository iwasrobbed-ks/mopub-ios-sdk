//
//  MPHTMLInterstitialViewController.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPHTMLInterstitialViewController.h"
#import "MPAdWebView.h"
#import "MPAdDestinationDisplayAgent.h"

@interface MPHTMLInterstitialViewController ()

@property (nonatomic, retain) MPAdWebView *backingView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPHTMLInterstitialViewController

@synthesize delegate = _delegate;

- (void)dealloc
{
    self.backingView.delegate = nil;
    self.backingView.customMethodDelegate = nil;
    self.backingView = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    self.backingView = [[[MPAdWebView alloc] initWithFrame:self.view.bounds
                                                  delegate:self
                                   destinationDisplayAgent:[MPAdDestinationDisplayAgent agentWithURLResolver:[MPURLResolver resolver]
                                                                                                    delegate:self]] autorelease];
    self.backingView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backingView];
}

#pragma mark - Public

- (id)customMethodDelegate
{
    return [self.backingView customMethodDelegate];
}

- (void)setCustomMethodDelegate:(id)delegate
{
    [self.backingView setCustomMethodDelegate:delegate];
}

- (void)loadConfiguration:(MPAdConfiguration *)configuration
{
    [self view];
    [self.backingView loadConfiguration:configuration];
}

- (void)willPresentInterstitial
{
    self.backingView.alpha = 0.0;
    [self.delegate interstitialWillAppear:self];
}

- (void)didPresentInterstitial
{
    self.backingView.dismissed = NO;

    [self.backingView invokeJavaScriptForEvent:MPAdWebViewEventAdDidAppear];

    // XXX: In certain cases, UIWebView's content appears off-center due to rotation / auto-
    // resizing while off-screen. -forceRedraw corrects this issue, but there is always a brief
    // instant when the old content is visible. We mask this using a short fade animation.
    [self.backingView forceRedraw];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.backingView.alpha = 1.0;
    [UIView commitAnimations];

    [self.delegate interstitialDidAppear:self];
}

- (void)willDismissInterstitial
{
    self.backingView.dismissed = YES;

    [self.delegate interstitialWillDisappear:self];
}

- (void)didDismissInterstitial
{
    [self.delegate interstitialDidDisappear:self];
}

#pragma mark - Autorotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self.backingView rotateToOrientation:self.interfaceOrientation];
}

#pragma mark - MPAdWebViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return self;
}

- (void)adDidFinishLoadingAd:(MPAdWebView *)ad
{
    [self.delegate interstitialDidLoadAd:self];
}

- (void)adDidFailToLoadAd:(MPAdWebView *)ad
{
    [self.delegate interstitialDidFailToLoadAd:self];
}

- (void)adActionWillBegin:(MPAdWebView *)ad
{
    [self.delegate interstitialWasTapped:self];
}

- (void)adActionWillLeaveApplication:(MPAdWebView *)ad
{
    [self.delegate interstitialWillLeaveApplication:self];
    [self dismissInterstitialAnimated:NO];
}

- (void)adActionDidFinish:(MPAdWebView *)ad
{
    //NOOP: the landing page is going away, but not the interstitial.
}

- (void)adDidClose:(MPAdWebView *)ad
{
    //NOOP: the ad is going away, but not the interstitial.
}

@end
