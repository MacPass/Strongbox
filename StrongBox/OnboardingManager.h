//
//  OnboardingManager.h
//  Strongbox
//
//  Created by Strongbox on 07/06/2021.
//  Copyright © 2021 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingManager : NSObject

+ (instancetype)sharedInstance;

- (void)startAppOnboarding:(UIViewController*)presentingViewController completion:(void (^ _Nullable)(void))completion;
- (void)startDatabaseOnboarding:(UIViewController*)presentingViewController model:(Model*)model completion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
