//
//  ALAppicAdMediationAdapter.h
//  APSKD
//
//  Created by gtq on 2025/9/1.
//  Copyright © 2025 Appic. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALAppicAdMediationAdapter : ALMediationAdapter <MAInterstitialAdapter, MAAppOpenAdapter, MARewardedAdapter, MAAdViewAdapter, MANativeAdAdapter>

@end

NS_ASSUME_NONNULL_END
