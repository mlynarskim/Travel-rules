//
//  GADInterstitialSignalRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/Request/GADSignalRequest.h>

/// An interstitial signal request that can be used as input in server-to-server signal
/// generation.
NS_SWIFT_NAME(InterstitialSignalRequest)
@interface GADInterstitialSignalRequest : GADSignalRequest

/// Returns an initialized interstitial signal request.
/// @param signalType The type of signal to request.
- (nonnull instancetype)initWithSignalType:(nonnull NSString *)signalType;

@end
