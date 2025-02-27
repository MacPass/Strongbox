//
//  StrongboxConstants.m
//  Strongbox
//
//  Created by Strongbox on 25/05/2021.
//  Copyright © 2021 Mark McGuill. All rights reserved.
//

#import "StrongboxErrorCodes.h"

static const NSInteger kIncorrectCredentials = -241;
static const NSInteger kCouldNotCreateICloudFile = -1334;

@implementation StrongboxErrorCodes

+ (NSInteger)incorrectCredentials {
    return kIncorrectCredentials;
}

+ (NSInteger)couldNotCreateICloudFile {
    return kCouldNotCreateICloudFile;
}

@end
