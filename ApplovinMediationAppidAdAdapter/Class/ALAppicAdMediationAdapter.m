//
//  ALAppicAdMediationAdapter.m
//  APSKD
//
//  Created by gtq on 2025/9/1.
//  Copyright © 2025 Appic. All rights reserved.
//

#import "ALAppicAdMediationAdapter.h"
#import <APSDK/APPch.h>

#define ADAPTER_VERSION @"5.1.1.1"

@interface ALAppicAdInterstitialDelegate : NSObject<APAdInterstitialDelegate>
@property (nonatomic, weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic, strong) NSString *placementIdentifier;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                  placementIdentifier:(NSString *)placementIdentifier
                            andNotify:(id<MAInterstitialAdapterDelegate>)delegate;

@end

@interface ALAppicAdSplashDelegate : NSObject <APAdSplashDelegate>
@property (nonatomic,   weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic, strong) NSString *placementIdentifier;
@property (nonatomic, strong) id<MAAppOpenAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                  placementIdentifier:(NSString *)placementIdentifier
                            andNotify:(id<MAAppOpenAdapterDelegate>)delegate;
@end

@interface ALAppicAdRewardedDelegate : NSObject <APAdRewardVideoDelegate>
@property (nonatomic,   weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic, strong) NSString *placementIdentifier;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> delegate;
@property (nonatomic, assign, getter=hasGrantedReward) BOOL grantedReward;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                  placementIdentifier:(NSString *)placementIdentifier
                            andNotify:(id<MARewardedAdapterDelegate>)delegate;
@end

@interface ALAppicAdAdViewDelegate : NSObject <APAdBannerViewDelegate>
@property (nonatomic,   weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic,   weak) MAAdFormat *adFormat;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                             adFormat:(MAAdFormat *)adFormat
                            andNotify:(id<MAAdViewAdapterDelegate>)delegate;
@end

@interface ALAppicAdNativeAdDelegate : NSObject <APAdNativeDelegate, APAdNativeVideoViewDelegate>
@property (nonatomic,   weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic, strong) NSDictionary<NSString *, id> *serverParameters;
@property (nonatomic, strong) id<MANativeAdAdapterDelegate> delegate;
@property (nonatomic,   copy) NSString *placementId;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                          parameters:(id<MAAdapterResponseParameters>)parameters
                            andNotify:(id<MANativeAdAdapterDelegate>)delegate;
@end

@interface MAAppicAdNativeAd : MANativeAd
@property (nonatomic,   weak) ALAppicAdMediationAdapter *parentAdapter;
@property (nonatomic, weak) MAAdFormat *adFormat;
- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter
                             adFormat:(MAAdFormat *)format
                         builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;
- (instancetype)initWithFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock NS_UNAVAILABLE;
@end

@interface ALAppicAdMediationAdapter ()<APSDKDelegate>

typedef void (^ALcompletionHandlerBlock)(MAAdapterInitializationStatus, NSString *_Nullable);

@property (nonatomic, strong) APAdInterstitial *interstitialAd;
@property (nonatomic, strong) APAdSplash *splashAd;
@property (nonatomic, strong) APAdRewardVideo *rewardedAd;
@property (nonatomic, strong) APAdBannerView *adView;
@property (nonatomic, strong) APAdNative *nativeAd;

@property (nonatomic, strong) ALAppicAdInterstitialDelegate *interstitialAdapterDelegate;
@property (nonatomic, strong) ALAppicAdSplashDelegate *splashAdapterDelegate;
@property (nonatomic, strong) ALAppicAdRewardedDelegate *rewardedAdapterDelegate;
@property (nonatomic, strong) ALAppicAdAdViewDelegate *adViewAdapterDelegate;
@property (nonatomic, strong) ALAppicAdNativeAdDelegate *nativeAdAdapterDelegate;

@property (nonatomic, weak) ALcompletionHandlerBlock alcompletionHandler;

@end


@implementation ALAppicAdMediationAdapter

#pragma mark - MAAdapter Methods

+ (void)load
{
    NSLog(@"ALAppicAdMediationAdapter loaded");
}

+ (NSString *)networkName
{
    return @"APSDK_Test"; // 要和后台 Custom Network Name 一致
}
- (NSString *)networkName
{
    return @"APSDK_Test"; // 要和后台 Custom Network Name 一致
}

- (NSString *)SDKVersion
{
    return [[APSDK sharedInstance] sdkVersion];
}

- (NSString *)adapterVersion
{
    return ADAPTER_VERSION;
}

- (void)destroy {
    self.interstitialAd.ap_delegate = nil;
    self.interstitialAd = nil;
    
    self.splashAd.ap_delegate = nil;
    self.splashAd = nil;
    
    self.rewardedAd.ap_delegate = nil;
    self.rewardedAd = nil;
    
    self.adView.ap_delegate = nil;
    self.adView = nil;
    
    self.nativeAd.ap_delegate = nil;
    self.nativeAd = nil;
}

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters completionHandler:(void (^)(MAAdapterInitializationStatus, NSString *_Nullable))completionHandler
{
    NSString * appid = [parameters.serverParameters objectForKey:@"app_id"];
    [self log: @"Initializing AppidAd SDK with app id: %@...", appid];
    if (appid && appid.length > 0) {
        self.alcompletionHandler = completionHandler;
        completionHandler(MAAdapterInitializationStatusInitializing, nil);
        [[APSDK sharedInstance] initWithAppId:appid andDelegate:self];
    } else {
        [self log: @"AppidAd SDK initialization failed with error: appid is nil"];
        completionHandler(MAAdapterInitializationStatusInitializedFailure, @"appid is nil");
    }
}

- (UIViewController *)getViewController:(nonnull id<MAAdapterResponseParameters>)parameters
{
    UIViewController *presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
    return presentingViewController;
}

#pragma mark - MAInterstitialAdapter Methods
- (void)loadInterstitialAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MAInterstitialAdapterDelegate>)delegate
{
    NSString * placementId = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading interstitial ad for placement: %@...", placementId];
    if (placementId && placementId.length > 0) {
        self.interstitialAdapterDelegate = [[ALAppicAdInterstitialDelegate alloc] initWithParentAdapter:self placementIdentifier:placementId andNotify:delegate];
        self.interstitialAd = [[APAdInterstitial alloc] initWithSlot:placementId andDelegate:self.interstitialAdapterDelegate];
        [self.interstitialAd load];
    }
}

- (void)showInterstitialAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MAInterstitialAdapterDelegate>)delegate
{
    [self log: @"Showing interstitial ad..."];
    if (self.interstitialAd && self.interstitialAd.ap_isReady) {
        [self.interstitialAd presentWithViewController:[self getViewController:parameters]];
    } else {
        [self log: @"Interstitial ad not ready"];
    }
}

- (void)loadAppOpenAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MAAppOpenAdapterDelegate>)delegate
{
    NSString * placementId = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading splash ad for placement: %@...", placementId];
    if (placementId && placementId.length > 0) {
        self.splashAdapterDelegate = [[ALAppicAdSplashDelegate alloc] initWithParentAdapter:self placementIdentifier:placementId andNotify:delegate];
        self.splashAd = [[APAdSplash alloc] initWithSlot:placementId andDelegate:self.splashAdapterDelegate];
        [self.splashAd load];
    }
}

- (void)showAppOpenAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MAAppOpenAdapterDelegate>)delegate
{
    if (self.splashAd) {
        [self log: @"show splash ad"];
        [self.splashAd presentWithViewController:[self getViewController:parameters]];
    }
}

- (void)loadRewardedAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MARewardedAdapterDelegate>)delegate
{
    NSString * placementId = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading reward ad for placement: %@...", placementId];
    if (placementId && placementId.length > 0) {
        self.rewardedAdapterDelegate = [[ALAppicAdRewardedDelegate alloc] initWithParentAdapter:self placementIdentifier:placementId andNotify:delegate];
        self.rewardedAd = [[APAdRewardVideo alloc] initWithSlot:placementId andDelegate:self.rewardedAdapterDelegate];
        [self.rewardedAd load];
    }
}

- (void)showRewardedAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MARewardedAdapterDelegate>)delegate
{
    if (self.rewardedAd && self.rewardedAd.ap_isReady) {
        [self.rewardedAd presentWithViewController:[self getViewController:parameters]];
    }
}

- (void)loadAdViewAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters adFormat:(nonnull MAAdFormat *)adFormat andNotify:(nonnull id<MAAdViewAdapterDelegate>)delegate
{
    NSString * placementId = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading banner ad for placement: %@...", placementId];
    if (placementId && placementId.length > 0) {
        self.adViewAdapterDelegate = [[ALAppicAdAdViewDelegate alloc] initWithParentAdapter:self adFormat:adFormat andNotify:delegate];
        CGRect frame = [self rectFromAdFormat:adFormat];
        APAdBannerSize bannerSize = APAdBannerSize320x50;
        if (frame.size.height == 90) {
            bannerSize = APAdBannerSize728x90;
        }
        self.adView = [[APAdBannerView alloc] initWithFrame:[self rectFromAdFormat:adFormat] Slot:placementId adSize:bannerSize delegate:self.adViewAdapterDelegate rootViewController:[self getViewController:parameters]];
        [self.adView load];
    }
}

- (CGRect)rectFromAdFormat:(MAAdFormat *)adFormat
{
    if ( adFormat == MAAdFormat.banner )
    {
        return CGRectMake(0, 0, 320, 50);
    }
    else if ( adFormat == MAAdFormat.leader )
    {
        return CGRectMake(0, 0, 728, 90);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Unsupported ad format: %@", adFormat];
        
        return CGRectMake(0, 0, 320, 50);
    }
}

- (void)loadNativeAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters andNotify:(nonnull id<MANativeAdAdapterDelegate>)delegate
{
    NSString * placementId = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading native ad for placement: %@...", placementId];
    if (placementId && placementId.length > 0) {
        self.nativeAdAdapterDelegate = [[ALAppicAdNativeAdDelegate alloc] initWithParentAdapter:self parameters:parameters andNotify:delegate];
        self.nativeAd = [[APAdNative alloc] initWithSlot:placementId andDelegate:self.nativeAdAdapterDelegate];
        [self.nativeAd load];
    }
}

#pragma mark APSDKDelegate
- (void)sdkDidInitialize
{
    if (self.alcompletionHandler) {
        self.alcompletionHandler(MAAdapterInitializationStatusInitializedSuccess, nil);
        self.alcompletionHandler = nil;
    }
}

- (void)sdkFailedToInitializeWithError:(NSError *)error
{
    if (self.alcompletionHandler) {
        self.alcompletionHandler(MAAdapterInitializationStatusInitializedFailure, error.description);
        self.alcompletionHandler = nil;
    }
    [self log:@"al adapter appic sdk init failed, error = %@", error];;
}
@end

@implementation MAAppicAdNativeAd

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter adFormat:(MAAdFormat *)format builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock
{
    self = [super initWithFormat:format builderBlock:builderBlock];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.adFormat = format;
    }
    return self;
}

@end

@implementation ALAppicAdNativeAdDelegate

#pragma mark APAdNativeAdDelegate

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter parameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.serverParameters = parameters.serverParameters;
        self.delegate = delegate;
        self.placementId = parameters.thirdPartyAdPlacementIdentifier;
    }
    return self;
}

- (void) apAdNativeDidLoadSuccess:(nonnull APAdNative *)ad
{
    if (!ad) {
        [self.parentAdapter log: @"Native ad failed to load: no fill"];
        [self.delegate didFailToLoadNativeAdWithError:MAAdapterError.noFill];
        return;
    }
    [self.parentAdapter log: @"Native ad loaded: %@", self.placementId];
    dispatchOnMainQueue(^{
        MANativeAd * maxNativeAd = [[MAAppicAdNativeAd alloc] initWithParentAdapter:self.parentAdapter adFormat:MAAdFormat.native builderBlock:^(MANativeAdBuilder * _Nonnull builder) {
            builder.title = ad.ap_adTitle;
            builder.body = ad.ap_adDescription;
            builder.icon = [[MANativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.ap_adIconUrl]];
            builder.mainImage = [[MANativeAdImage alloc] initWithURL:[NSURL URLWithString:ad.ap_adScreenshotUrl]];
            builder.mediaView = [[UIView alloc] init];
            [ad registerContainerView:builder.mediaView];
        }];
        [self.delegate didLoadAdForNativeAd:maxNativeAd withExtraInfo:nil];
    });
}

- (void) apAdNativeDidLoadFail:(nonnull APAdNative *)ad withError:(nonnull NSError *)err
{
    MAAdapterError * maError = [MAAdapterError errorWithNSError:err];
    [self.parentAdapter log: @"Native ad failed to load with error: %@", maError];
    [self.delegate didFailToLoadNativeAdWithError:maError];
}

- (void) apAdNativeDidPresentSuccess:(nonnull APAdNative *) ad
{
    [self.parentAdapter log: @"Native ad did present"];
    [self.delegate didDisplayNativeAdWithExtraInfo:nil];
}

- (void) apAdNativeDidClick:(nonnull APAdNative *)ad
{
    [self.parentAdapter log: @"Native ad clicked"];
    [self.delegate didClickNativeAd];
}

- (void) apAdNativeDidPresentLanding:(nonnull APAdNative *)ad
{
    
}

- (void) apAdNativeDidDismissLanding:(nonnull APAdNative *)ad
{
    
}

- (void) apAdNativeApplicationWillEnterBackground:(nonnull APAdNative *)ad
{
    
}

#pragma mark APAdNativeVideoDelegate
- (void) apAdNativeVideoView:(nonnull APAdNativeVideoView *)view didChangeState:(APAdNativeVideoState)state
{
    
}

- (void) apAdNativeVideoViewDidPlayFinish:(nonnull APAdNativeVideoView *)view
{
    
}

@end

@implementation ALAppicAdAdViewDelegate

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter adFormat:(MAAdFormat *)adFormat andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.adFormat = adFormat;
        self.delegate = delegate;
    }
    return self;
}

- (void) apAdBannerViewDidLoadSuccess:(nonnull APAdBannerView *)ad
{
    [self.parentAdapter log: @"AdView loaded"];
    [self.delegate didLoadAdForAdView:ad];
}

- (void) apAdBannerViewDidLoadFail:(nonnull APAdBannerView *)ad
                         withError:(nonnull NSError *)err
{
    MAAdapterError * adapterError = [MAAdapterError errorWithNSError:err];
    [self.parentAdapter log: @"AdView failed to load with error: %@", adapterError];
    [self.delegate didFailToLoadAdViewAdWithError: adapterError];
}

- (void) apAdBannerViewDidPresentSuccess:(nonnull APAdBannerView *)ad
{
    [self.parentAdapter log: @"AdView impression tracked"];
    [self.delegate didDisplayAdViewAd];
}

- (void) apAdBannerViewDidClick:(nonnull APAdBannerView *)ad
{
    [self.parentAdapter log: @"AdView clicked"];
    [self.delegate didClickAdViewAd];
}

@end

@implementation ALAppicAdInterstitialDelegate

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter placementIdentifier:(NSString *)placementIdentifier andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.placementIdentifier = placementIdentifier;
        self.delegate = delegate;
    }
    return self;
}

- (void) apAdInterstitialDidLoadSuccess:(nonnull APAdInterstitial *) ad
{
    [self.parentAdapter log: @"AdView loaded"];
    [self.delegate didLoadInterstitialAd];
}

- (void) apAdInterstitialDidLoadFail:(nonnull APAdInterstitial *) ad
                           withError:(nonnull NSError *) err
{
    MAAdapterError * adapterError = [MAAdapterError errorWithNSError:err];
    [self.parentAdapter log: @"Interstitial failed to load with error: %@", adapterError];
    [self.delegate didFailToLoadInterstitialAdWithError: adapterError];
}

- (void) apAdInterstitialDidPresentSuccess:(nonnull APAdInterstitial *) ad
{
    [self.parentAdapter log: @"Interstitial impression tracked"];
    [self.delegate didDisplayInterstitialAd];
}

- (void) apAdInterstitialDidPresentFail:(nonnull APAdInterstitial *)ad withError:(nonnull NSError *)err
{
    [self.parentAdapter log: @"Interstitial failed to display with error: %@", err];
    
    MAAdapterError *adapterError = [MAAdapterError errorWithAdapterError: MAAdapterError.adDisplayFailedError
                                                mediatedNetworkErrorCode: err.code
                                             mediatedNetworkErrorMessage: err.localizedDescription];
    [self.delegate didFailToDisplayInterstitialAdWithError: adapterError];

}

- (void) apAdInterstitialDidClick:(nonnull APAdInterstitial *) ad
{
    [self.parentAdapter log: @"Interstitial clicked"];
    [self.delegate didClickInterstitialAd];
}

- (void) apAdInterstitialDidPresentLanding:(nonnull APAdInterstitial *)ad
{
    
}

- (void) apAdInterstitialDidDismissLanding:(nonnull APAdInterstitial *)ad
{
    
}

- (void) apAdInterstitialApplicationWillEnterBackground:(nonnull APAdInterstitial *)ad
{
    
}

- (void) apAdInterstitialDidDismiss:(nonnull APAdInterstitial *)ad
{
    [self.parentAdapter log: @"Interstitial hidden"];
    [self.delegate didHideInterstitialAd];
}

@end

@implementation ALAppicAdSplashDelegate

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter placementIdentifier:(NSString *)placementIdentifier andNotify:(id<MAAppOpenAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.placementIdentifier = placementIdentifier;
        self.delegate = delegate;
    }
    
    return self;
}

- (void) apAdSplashDidLoadSuccess:(nonnull APAdSplash *)ad
{
    [self.parentAdapter log: @"App open ad load success: %@", self.placementIdentifier];
    [self.delegate didLoadAppOpenAd];
}

- (void) apAdSplashDidLoadFail:(nonnull APAdSplash *)ad withError:(nonnull NSError *)err
{
    MAAdapterError *adapterError = [MAAdapterError errorWithNSError:err];
    [self.parentAdapter log: @"App open ad (%@) failed to load with error: %@", self.placementIdentifier, adapterError];
    [self.delegate didFailToLoadAppOpenAdWithError: adapterError];
}

- (void) apAdSplashDidPresentSuccess:(nonnull APAdSplash *)ad
{
    [self.parentAdapter log: @"App open ad impression recorded: %@", self.placementIdentifier];
    [self.delegate didDisplayAppOpenAd];
}

- (void) apAdSplashDidPresentFail:(nonnull APAdSplash *)ad withError:(nonnull NSError *)err
{
    MAAdapterError *adapterError = [MAAdapterError errorWithAdapterError: MAAdapterError.adDisplayFailedError
                                                mediatedNetworkErrorCode: err.code
                                             mediatedNetworkErrorMessage: err.localizedDescription];
    [self.parentAdapter log: @"App open ad (%@) failed to show with error: %@", self.placementIdentifier, adapterError];
    [self.delegate didFailToDisplayAppOpenAdWithError: adapterError];
}

- (void) apAdSplashDidClick:(nonnull APAdSplash *)ad
{
    [self.parentAdapter log: @"App open ad click recorded: %@", self.placementIdentifier];
    [self.delegate didClickAppOpenAd];
}

- (void) apAdSplashDidPresentLanding:(nonnull APAdSplash *)ad
{
    
}

- (void) apAdSplashDidDismissLanding:(nonnull APAdSplash *)ad
{
    
}

- (void) apAdSplashApplicationWillEnterBackground:(nonnull APAdSplash *)ad
{
    
}

- (void) apAdSplashDidDismiss:(nonnull APAdSplash *)ad
{
    [self.parentAdapter log: @"App open ad hidden: %@", self.placementIdentifier];
    [self.delegate didHideAppOpenAd];
}

- (void) apAdSplashDidPresentTimeLeft:(NSUInteger)time
{
    
}

@end

@implementation ALAppicAdRewardedDelegate

- (instancetype)initWithParentAdapter:(ALAppicAdMediationAdapter *)parentAdapter placementIdentifier:(NSString *)placementIdentifier andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.parentAdapter = parentAdapter;
        self.placementIdentifier = placementIdentifier;
        self.delegate = delegate;
    }
    return self;
}

- (void) apAdRewardVideoDidLoadSuccess:(nonnull APAdRewardVideo *)ad
{
    [self.parentAdapter log: @"Rewarded ad load success: %@", self.placementIdentifier];
    [self.delegate didLoadRewardedAd];

}

- (void) apAdRewardVideoDidLoadFail:(nonnull APAdRewardVideo *)ad withError:(nonnull NSError *)err
{
    [self.parentAdapter log: @"Rewarded ad load failed: %@", self.placementIdentifier];
    [self.delegate didFailToLoadRewardedAdWithError:[MAAdapterError errorWithNSError:err]];
}

- (void) apAdRewardVideoDidPresentSuccess:(nonnull APAdRewardVideo *)ad
{
    [self.parentAdapter log: @"Rewarded ad impression recorded: %@", self.placementIdentifier];
    [self.delegate didDisplayRewardedAd];
}

- (void) apAdRewardVideoDidPresentFail:(nonnull APAdRewardVideo *)ad withError:(nonnull NSError *)err
{
    MAAdapterError *adapterError = [MAAdapterError errorWithAdapterError: MAAdapterError.adDisplayFailedError
                                                mediatedNetworkErrorCode: err.code
                                             mediatedNetworkErrorMessage: err.localizedDescription];
    [self.parentAdapter log: @"Rewarded ad (%@) failed to show: %@", self.placementIdentifier, adapterError];
    [self.delegate didFailToDisplayRewardedAdWithError: adapterError];
}

- (void) apAdRewardVideoDidClick:(nonnull APAdRewardVideo *)ad
{
    [self.parentAdapter log: @"Rewarded ad click recorded: %@", self.placementIdentifier];
    [self.delegate didClickRewardedAd];
}

- (void) apAdRewardVideoDidPlayComplete:(nonnull APAdRewardVideo *)ad
{
    
}

- (void) apAdRewardVideoDidDismiss:(nonnull APAdRewardVideo *)ad
{
    [self.parentAdapter log: @"Rewarded ad hidden: %@", self.placementIdentifier];
    [self.delegate didHideRewardedAd];
}

@end
