//
//  SafeDetails.m
//  StrongBox
//
//  Created by Mark McGuill on 05/06/2014.
//  Copyright (c) 2014 Mark McGuill. All rights reserved.
//

#import "SafeMetaData.h"
#import "SecretStore.h"
#import "FileManager.h"
#import "ItemDetailsViewController.h"

#ifndef IS_APP_EXTENSION
#import "SafeStorageProviderFactory.h"
#endif

#import "AppPreferences.h"

static const NSInteger kDefaultConvenienceExpiryPeriodHours = -1; 
static const NSUInteger kDefaultScheduledExportIntervalDays = 28;  

@interface SafeMetaData ()

@property (nullable) YubiKeyHardwareConfiguration* yubiKeyConfig;
@property (nullable) YubiKeyHardwareConfiguration* autoFillYubiKeyConfig;

@end

@implementation SafeMetaData

- (BOOL)viewDereferencedFields {
    return YES;
}

- (BOOL)searchDereferencedFields {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uuid = [[NSUUID UUID] UUIDString];
        self.failedPinAttempts = 0;
        self.likelyFormat = kFormatUnknown;
        self.browseViewType = kBrowseViewTypeHierarchy;
        self.browseSortField = kBrowseSortFieldTitle;
        self.browseSortFoldersSeparately = YES;
        self.browseItemSubtitleField = kBrowseItemSubtitleUsername;
        self.showChildCountOnFolderInBrowse = YES;
        self.showFlagsInBrowse = YES;
        self.detailsViewCollapsedSections = ItemDetailsViewController.defaultCollapsedSections;
        self.tryDownloadFavIconForNewRecord = YES;
        self.showExpiredInBrowse = YES;
        self.showExpiredInSearch = YES;
        self.autoLockTimeoutSeconds = @60;
        self.showQuickViewFavourites = YES;
        self.showQuickViewNearlyExpired = YES;

        
        
        
        
        self.makeBackups = YES;
        self.maxBackupKeepCount = 10;
        self.hideTotpCustomFieldsInViewMode = YES;
        
        self.tapAction = kBrowseTapActionOpenDetails;

        
        self.doubleTapAction = kBrowseTapActionCopyPassword;
        self.tripleTapAction = kBrowseTapActionCopyTotp;
        self.longPressTapAction = kBrowseTapActionCopyUsername;

        self.colorizePasswords = YES;
        self.keePassIconSet = kKeePassIconSetSfSymbols;
        self.auditConfig = DatabaseAuditorConfiguration.defaults;
        
        self.conflictResolutionStrategy = kConflictResolutionStrategyAutoMerge;
        self.quickTypeDisplayFormat = kQuickTypeFormatTitleThenUsername;
        self.autoLockOnDeviceLock = YES;
        self.autoFillConvenienceAutoUnlockTimeout = -1;
        self.quickTypeEnabled = YES;
        self.autoFillCopyTotp = YES;
        self.convenienceExpiryPeriod = kDefaultConvenienceExpiryPeriodHours;
        self.showConvenienceExpiryMessage = YES;
        self.scheduleExportIntervalDays = kDefaultScheduledExportIntervalDays;
        self.databaseCreated = NSDate.date;
        self.unlockCount = 0;
        
        self.autoFillScanAltUrls = YES;
        self.autoFillScanCustomFields = NO;
        self.autoFillScanNotes = NO;
    }
    
    return self;
}

- (instancetype)initWithNickName:(NSString *)nickName
                 storageProvider:(StorageProvider)storageProvider
                        fileName:(NSString*)fileName
                  fileIdentifier:(NSString*)fileIdentifier {
    if(self = [self init]) {
        if(!nickName.length) {
            NSLog(@"WARNWARN: No Nick Name set... auto generating.");
            self.nickName = NSUUID.UUID.UUIDString;
        }
        else {
            self.nickName = nickName;
        }
        
        self.storageProvider = storageProvider;
        self.fileName = fileName;
        self.fileIdentifier = fileIdentifier;
        
        
        
        BOOL immediateOfflineOfferIfOfflineDetected = [SafeMetaData defaultImmediatelyOfferOfflineForProvider:storageProvider];
        self.offlineDetectedBehaviour = immediateOfflineOfferIfOfflineDetected ? kOfflineDetectedBehaviourAsk : kOfflineDetectedBehaviourTryConnectThenAsk;
        self.couldNotConnectBehaviour = kCouldNotConnectBehaviourPrompt;
    }
    
    return self;
}

+ (BOOL)defaultImmediatelyOfferOfflineForProvider:(StorageProvider)storageProvider {
#ifndef IS_APP_EXTENSION
    id <SafeStorageProvider> provider = [SafeStorageProviderFactory getStorageProviderFromProviderId:storageProvider];
    return provider.defaultForImmediatelyOfferOfflineCache;
#else
    return NO;
#endif
}




+ (instancetype)fromJsonSerializationDictionary:(NSDictionary *)jsonDictionary {
    SafeMetaData *ret = [[SafeMetaData alloc] init];

    if ( jsonDictionary[@"uuid"] != nil) ret.uuid = jsonDictionary[@"uuid"];
    if ( jsonDictionary[@"nickName"] != nil ) ret.nickName = jsonDictionary[@"nickName"];
    if ( jsonDictionary[@"fileName"] != nil ) ret.fileName = jsonDictionary[@"fileName"];
    if ( jsonDictionary[@"fileIdentifier"] != nil ) ret.fileIdentifier = jsonDictionary[@"fileIdentifier"];
    if ( jsonDictionary[@"keyFileBookmark"] != nil ) ret.keyFileBookmark = jsonDictionary[@"keyFileBookmark"];
    if ( jsonDictionary[@"autoLockTimeoutSeconds"] != nil ) ret.autoLockTimeoutSeconds = jsonDictionary[@"autoLockTimeoutSeconds"];
    if ( jsonDictionary[@"detailsViewCollapsedSections"] != nil ) ret.detailsViewCollapsedSections = jsonDictionary[@"detailsViewCollapsedSections"];
    if ( jsonDictionary[@"failedPinAttempts"] != nil ) ret.failedPinAttempts = ((NSNumber*)jsonDictionary[@"failedPinAttempts"]).intValue;
    
    if ( jsonDictionary[@"autoFillEnabled"] != nil ) ret.autoFillEnabled = ((NSNumber*)jsonDictionary[@"autoFillEnabled"]).boolValue;
    if ( jsonDictionary[@"browseSortOrderDescending"] != nil ) ret.browseSortOrderDescending = ((NSNumber*)jsonDictionary[@"browseSortOrderDescending"]).boolValue;
    if ( jsonDictionary[@"browseSortFoldersSeparately"] != nil ) ret.browseSortFoldersSeparately = ((NSNumber*)jsonDictionary[@"browseSortFoldersSeparately"]).boolValue;
    if ( jsonDictionary[@"immediateSearchOnBrowse"] != nil ) ret.immediateSearchOnBrowse = ((NSNumber*)jsonDictionary[@"immediateSearchOnBrowse"]).boolValue;
    if ( jsonDictionary[@"hideTotpInBrowse"] != nil ) ret.hideTotpInBrowse = ((NSNumber*)jsonDictionary[@"hideTotpInBrowse"]).boolValue;
    if ( jsonDictionary[@"showKeePass1BackupGroup"] != nil ) ret.showKeePass1BackupGroup = ((NSNumber*)jsonDictionary[@"showKeePass1BackupGroup"]).boolValue;
    if ( jsonDictionary[@"showChildCountOnFolderInBrowse"] != nil ) ret.showChildCountOnFolderInBrowse = ((NSNumber*)jsonDictionary[@"showChildCountOnFolderInBrowse"]).boolValue;
    if ( jsonDictionary[@"showFlagsInBrowse"] != nil ) ret.showFlagsInBrowse = ((NSNumber*)jsonDictionary[@"showFlagsInBrowse"]).boolValue;
    if ( jsonDictionary[@"doNotShowRecycleBinInBrowse"] != nil ) ret.doNotShowRecycleBinInBrowse = ((NSNumber*)jsonDictionary[@"doNotShowRecycleBinInBrowse"]).boolValue;
    if ( jsonDictionary[@"showRecycleBinInSearchResults"] != nil ) ret.showRecycleBinInSearchResults = ((NSNumber*)jsonDictionary[@"showRecycleBinInSearchResults"]).boolValue;


    if ( jsonDictionary[@"showEmptyFieldsInDetailsView"] != nil ) ret.showEmptyFieldsInDetailsView = ((NSNumber*)jsonDictionary[@"showEmptyFieldsInDetailsView"]).boolValue;
    if ( jsonDictionary[@"easyReadFontForAll"] != nil ) ret.easyReadFontForAll = ((NSNumber*)jsonDictionary[@"easyReadFontForAll"]).boolValue;
    if ( jsonDictionary[@"hideTotp"] != nil ) ret.hideTotp = ((NSNumber*)jsonDictionary[@"hideTotp"]).boolValue;
    if ( jsonDictionary[@"tryDownloadFavIconForNewRecord"] != nil ) ret.tryDownloadFavIconForNewRecord = ((NSNumber*)jsonDictionary[@"tryDownloadFavIconForNewRecord"]).boolValue;
    if ( jsonDictionary[@"showPasswordByDefaultOnEditScreen"] != nil ) ret.showPasswordByDefaultOnEditScreen = ((NSNumber*)jsonDictionary[@"showPasswordByDefaultOnEditScreen"]).boolValue;
    if ( jsonDictionary[@"showExpiredInBrowse"] != nil ) ret.showExpiredInBrowse = ((NSNumber*)jsonDictionary[@"showExpiredInBrowse"]).boolValue;
    if ( jsonDictionary[@"showExpiredInSearch"] != nil ) ret.showExpiredInSearch = ((NSNumber*)jsonDictionary[@"showExpiredInSearch"]).boolValue;
    if ( jsonDictionary[@"showQuickViewFavourites"] != nil ) ret.showQuickViewFavourites = ((NSNumber*)jsonDictionary[@"showQuickViewFavourites"]).boolValue;
    if ( jsonDictionary[@"showQuickViewNearlyExpired"] != nil ) ret.showQuickViewNearlyExpired = ((NSNumber*)jsonDictionary[@"showQuickViewNearlyExpired"]).boolValue;
    if ( jsonDictionary[@"makeBackups"] != nil ) ret.makeBackups = ((NSNumber*)jsonDictionary[@"makeBackups"]).boolValue;
    if ( jsonDictionary[@"hideTotpCustomFieldsInViewMode"] != nil ) ret.hideTotpCustomFieldsInViewMode = ((NSNumber*)jsonDictionary[@"hideTotpCustomFieldsInViewMode"]).boolValue;
    if ( jsonDictionary[@"hideIconInBrowse"] != nil ) ret.hideIconInBrowse = ((NSNumber*)jsonDictionary[@"hideIconInBrowse"]).boolValue;
    if ( jsonDictionary[@"colorizePasswords"] != nil ) ret.colorizePasswords = ((NSNumber*)jsonDictionary[@"colorizePasswords"]).boolValue;
    if ( jsonDictionary[@"isTouchIdEnabled"] != nil ) ret.isTouchIdEnabled = ((NSNumber*)jsonDictionary[@"isTouchIdEnabled"]).boolValue;
    if ( jsonDictionary[@"isEnrolledForConvenience"] != nil ) ret.isEnrolledForConvenience = ((NSNumber*)jsonDictionary[@"isEnrolledForConvenience"]).boolValue;
    if ( jsonDictionary[@"hasUnresolvedConflicts"] != nil ) ret.hasUnresolvedConflicts = ((NSNumber*)jsonDictionary[@"hasUnresolvedConflicts"]).boolValue;
    if ( jsonDictionary[@"readOnly"] != nil ) ret.readOnly = ((NSNumber*)jsonDictionary[@"readOnly"]).boolValue;
    if ( jsonDictionary[@"hasBeenPromptedForConvenience"] != nil ) ret.hasBeenPromptedForConvenience = ((NSNumber*)jsonDictionary[@"hasBeenPromptedForConvenience"]).boolValue;
    if ( jsonDictionary[@"hasBeenPromptedForQuickLaunch"] != nil ) ret.hasBeenPromptedForQuickLaunch = ((NSNumber*)jsonDictionary[@"hasBeenPromptedForQuickLaunch"]).boolValue;
    if ( jsonDictionary[@"showQuickViewExpired"] != nil ) ret.showQuickViewExpired = ((NSNumber*)jsonDictionary[@"showQuickViewExpired"]).boolValue;
    if ( jsonDictionary[@"colorizeProtectedCustomFields"] != nil ) ret.colorizeProtectedCustomFields = ((NSNumber*)jsonDictionary[@"colorizeProtectedCustomFields"]).boolValue;
    if ( jsonDictionary[@"promptedForAutoFetchFavIcon"] != nil ) ret.promptedForAutoFetchFavIcon = ((NSNumber*)jsonDictionary[@"promptedForAutoFetchFavIcon"]).boolValue;
    if ( jsonDictionary[@"lockEvenIfEditing"] != nil ) ret.lockEvenIfEditing = ((NSNumber*)jsonDictionary[@"lockEvenIfEditing"]).boolValue;
    
    if ( jsonDictionary[@"keePassIconSet"] != nil ) ret.keePassIconSet = ((NSNumber*)jsonDictionary[@"keePassIconSet"]).unsignedIntegerValue;
    if ( jsonDictionary[@"browseItemSubtitleField"] != nil ) ret.browseItemSubtitleField = ((NSNumber*)jsonDictionary[@"browseItemSubtitleField"]).unsignedIntegerValue;
    if ( jsonDictionary[@"likelyFormat"] != nil ) ret.likelyFormat = ((NSNumber*)jsonDictionary[@"likelyFormat"]).unsignedIntegerValue;
    if ( jsonDictionary[@"browseViewType"] != nil ) ret.browseViewType = ((NSNumber*)jsonDictionary[@"browseViewType"]).unsignedIntegerValue;
    if ( jsonDictionary[@"browseSortField"] != nil ) ret.browseSortField = ((NSNumber*)jsonDictionary[@"browseSortField"]).unsignedIntegerValue;
    if ( jsonDictionary[@"maxBackupKeepCount"] != nil ) ret.maxBackupKeepCount = ((NSNumber*)jsonDictionary[@"maxBackupKeepCount"]).unsignedIntegerValue;
    if ( jsonDictionary[@"tapAction"] != nil ) ret.tapAction = ((NSNumber*)jsonDictionary[@"tapAction"]).unsignedIntegerValue;
    if ( jsonDictionary[@"doubleTapAction"] != nil ) ret.doubleTapAction = ((NSNumber*)jsonDictionary[@"doubleTapAction"]).unsignedIntegerValue;
    if ( jsonDictionary[@"tripleTapAction"] != nil ) ret.tripleTapAction = ((NSNumber*)jsonDictionary[@"tripleTapAction"]).unsignedIntegerValue;
    if ( jsonDictionary[@"longPressTapAction"] != nil ) ret.longPressTapAction = ((NSNumber*)jsonDictionary[@"longPressTapAction"]).unsignedIntegerValue;
    if ( jsonDictionary[@"storageProvider"] != nil ) ret.storageProvider = ((NSNumber*)jsonDictionary[@"storageProvider"]).unsignedIntegerValue;
    if ( jsonDictionary[@"duressAction"] != nil ) ret.duressAction = ((NSNumber*)jsonDictionary[@"duressAction"]).unsignedIntegerValue;
    if ( jsonDictionary[@"failedPinAttempts"] != nil ) ret.failedPinAttempts = ((NSNumber*)jsonDictionary[@"failedPinAttempts"]).intValue;
    
    if ( jsonDictionary[@"yubiKeyConfig"] != nil ) ret.yubiKeyConfig = [YubiKeyHardwareConfiguration fromJsonSerializationDictionary:jsonDictionary[@"yubiKeyConfig"]];
    if ( jsonDictionary[@"autoFillYubiKeyConfig"] != nil ) ret.autoFillYubiKeyConfig = [YubiKeyHardwareConfiguration fromJsonSerializationDictionary:jsonDictionary[@"autoFillYubiKeyConfig"]];

    if ( jsonDictionary[@"auditConfig"] != nil ) ret.auditConfig = [DatabaseAuditorConfiguration fromJsonSerializationDictionary:jsonDictionary[@"auditConfig"]];

    if ( jsonDictionary[@"outstandingUpdateId"] != nil) ret.outstandingUpdateId = [[NSUUID alloc] initWithUUIDString:jsonDictionary[@"outstandingUpdateId"]];
    if ( jsonDictionary[@"lastSyncRemoteModDate"] != nil ) ret.lastSyncRemoteModDate = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"lastSyncRemoteModDate"])).doubleValue];
    if ( jsonDictionary[@"lastSyncAttempt"] != nil ) ret.lastSyncAttempt = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"lastSyncAttempt"])).doubleValue];

    if ( jsonDictionary[@"conflictResolutionStrategy"] != nil ) ret.conflictResolutionStrategy = ((NSNumber*)jsonDictionary[@"conflictResolutionStrategy"]).unsignedIntegerValue;
    
    if ( jsonDictionary[@"quickTypeEnabled"] != nil ) {
        ret.quickTypeEnabled = ((NSNumber*)jsonDictionary[@"quickTypeEnabled"]).boolValue;
    }
    else { 
        ret.quickTypeEnabled = YES;
    }
    
    if ( jsonDictionary[@"quickTypeDisplayFormat"] != nil ) {
        ret.quickTypeDisplayFormat = ((NSNumber*)jsonDictionary[@"quickTypeDisplayFormat"]).integerValue;
    }
    else { 
        ret.quickTypeDisplayFormat = kQuickTypeFormatTitleThenUsername;
    }
    
    
    
    if ( jsonDictionary[@"emptyOrNilPwPreferNilCheckFirst"] != nil ) {
        ret.emptyOrNilPwPreferNilCheckFirst = ((NSNumber*)jsonDictionary[@"emptyOrNilPwPreferNilCheckFirst"]).boolValue;
    }
    
    
    
    if ( jsonDictionary[@"autoLockOnDeviceLock"] != nil ) {
        ret.autoLockOnDeviceLock = ((NSNumber*)jsonDictionary[@"autoLockOnDeviceLock"]).boolValue;
    }
    else { 
        ret.autoLockOnDeviceLock = YES;
    }
    
    
    
    if ( jsonDictionary[@"autoFillConvenienceAutoUnlockTimeout"] != nil ) {
        ret.autoFillConvenienceAutoUnlockTimeout = ((NSNumber*)jsonDictionary[@"autoFillConvenienceAutoUnlockTimeout"]).integerValue;
    }
    else { 
        ret.autoFillConvenienceAutoUnlockTimeout = -1;
    }
    
    
    
    if ( jsonDictionary[@"autoFillLastUnlockedAt"] != nil ) {
        ret.autoFillLastUnlockedAt = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"autoFillLastUnlockedAt"])).doubleValue];
    }
    
    
    
    if ( jsonDictionary[@"autoFillCopyTotp"] != nil ) {
        ret.autoFillCopyTotp = ((NSNumber*)jsonDictionary[@"autoFillCopyTotp"]).boolValue;
    }
    else { 
        ret.autoFillCopyTotp = YES;
    }
    
    
    
    if ( jsonDictionary[@"forceOpenOffline"] != nil ) ret.forceOpenOffline = ((NSNumber*)jsonDictionary[@"forceOpenOffline"]).boolValue;

    
    
    if ( jsonDictionary[@"offlineDetectedBehaviour"] != nil ) {
        ret.offlineDetectedBehaviour = ((NSNumber*)jsonDictionary[@"offlineDetectedBehaviour"]).integerValue;
    }
    else { 
        BOOL immediateOfflineOfferIfOfflineDetected = [SafeMetaData defaultImmediatelyOfferOfflineForProvider:ret.storageProvider];
        ret.offlineDetectedBehaviour = immediateOfflineOfferIfOfflineDetected ? kOfflineDetectedBehaviourAsk : kOfflineDetectedBehaviourTryConnectThenAsk;
    }

    
    
    if ( jsonDictionary[@"couldNotConnectBehaviour"] != nil ) {
        ret.couldNotConnectBehaviour = ((NSNumber*)jsonDictionary[@"couldNotConnectBehaviour"]).integerValue;
    }
    
    
    
    if ( jsonDictionary[@"convenienceExpiryPeriod"] != nil ) {
        ret.convenienceExpiryPeriod = ((NSNumber*)jsonDictionary[@"convenienceExpiryPeriod"]).integerValue;
    }
    else { 
        ret.convenienceExpiryPeriod = -1; 
    }
    
    
    
    if ( jsonDictionary[@"showConvenienceExpiryMessage"] != nil ) {
        ret.showConvenienceExpiryMessage = ((NSNumber*)jsonDictionary[@"showConvenienceExpiryMessage"]).boolValue;
    }
    else { 
        ret.showConvenienceExpiryMessage = YES;
    }

    
    
    if ( jsonDictionary[@"hasShownInitialOnboardingScreen"] != nil ) {
        ret.hasShownInitialOnboardingScreen = ((NSNumber*)jsonDictionary[@"hasShownInitialOnboardingScreen"]).boolValue;
    }
    else { 
        ret.hasShownInitialOnboardingScreen = YES;
    }
    
    
    
    
    if ( jsonDictionary[@"convenienceExpiryOnboardingDone"] != nil ) {
        ret.convenienceExpiryOnboardingDone = ((NSNumber*)jsonDictionary[@"convenienceExpiryOnboardingDone"]).boolValue;
    }

    if ( jsonDictionary[@"autoFillOnboardingDone"] != nil ) {
        ret.autoFillOnboardingDone = ((NSNumber*)jsonDictionary[@"autoFillOnboardingDone"]).boolValue;
    }
    else { 
        ret.autoFillOnboardingDone = YES;
    }

    
    
    if ( jsonDictionary[@"hasAcknowledgedAppLockBiometricQuickLaunchCoalesceIssue"] != nil ) {
        ret.hasAcknowledgedAppLockBiometricQuickLaunchCoalesceIssue = ((NSNumber*)jsonDictionary[@"hasAcknowledgedAppLockBiometricQuickLaunchCoalesceIssue"]).boolValue;
    }
    
    
    
    if ( jsonDictionary[@"onboardingDoneHasBeenShown"] != nil ) {
        ret.onboardingDoneHasBeenShown = ((NSNumber*)jsonDictionary[@"onboardingDoneHasBeenShown"]).boolValue;
    }
    else { 
        ret.onboardingDoneHasBeenShown = YES;
    }

    
    
    if ( jsonDictionary[@"scheduledExport"] != nil ) {
        ret.scheduledExport = ((NSNumber*)jsonDictionary[@"scheduledExport"]).boolValue;
    }
    
    if ( jsonDictionary[@"scheduledExportOnboardingDone"] != nil ) {
        ret.scheduledExportOnboardingDone = ((NSNumber*)jsonDictionary[@"scheduledExportOnboardingDone"]).boolValue;
    }

    if ( jsonDictionary[@"scheduleExportIntervalDays"] != nil ) {
        ret.scheduleExportIntervalDays = ((NSNumber*)jsonDictionary[@"scheduleExportIntervalDays"]).unsignedIntegerValue;
    }
    else {
        ret.scheduleExportIntervalDays = kDefaultScheduledExportIntervalDays;
    }
    
    if ( jsonDictionary[@"nextScheduledExport"] != nil ) {
        ret.nextScheduledExport = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"nextScheduledExport"])).doubleValue];
    }

    if ( jsonDictionary[@"lastScheduledExportModDate"] != nil ) {
        ret.lastScheduledExportModDate = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"lastScheduledExportModDate"])).doubleValue];
    }
    
    if ( jsonDictionary[@"databaseCreated"] != nil ) {
        ret.databaseCreated = [NSDate dateWithTimeIntervalSinceReferenceDate:((NSNumber*)(jsonDictionary[@"databaseCreated"])).doubleValue];
    }
    else {
        ret.databaseCreated = NSDate.date;
    }
    
    if ( jsonDictionary[@"unlockCount"] != nil ) {
        ret.unlockCount = ((NSNumber*)jsonDictionary[@"unlockCount"]).unsignedIntegerValue;
    }

    
    
    if ( jsonDictionary[@"autoFillScanAltUrls"] != nil ) {
        ret.autoFillScanAltUrls = ((NSNumber*)jsonDictionary[@"autoFillScanAltUrls"]).boolValue;
    }
    else {
        ret.autoFillScanAltUrls = YES;
    }

    
    
    if ( jsonDictionary[@"autoFillScanCustomFields"] != nil ) {
        ret.autoFillScanCustomFields = ((NSNumber*)jsonDictionary[@"autoFillScanCustomFields"]).boolValue;
    }
    else {
        ret.autoFillScanCustomFields = YES;
    }

    
    
    if ( jsonDictionary[@"autoFillScanNotes"] != nil ) {
        ret.autoFillScanNotes = ((NSNumber*)jsonDictionary[@"autoFillScanNotes"]).boolValue;
    }
    else {
        ret.autoFillScanNotes = YES;
    }

    return ret;
}

- (NSDictionary *)getJsonSerializationDictionary {
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithDictionary:@{
        @"uuid" : self.uuid,
        @"failedPinAttempts" : @(self.failedPinAttempts),
        @"autoFillEnabled" : @(self.autoFillEnabled),
        @"likelyFormat" : @(self.likelyFormat),
        @"browseViewType" : @(self.browseViewType),
        @"browseSortField" : @(self.browseSortField),
        @"browseSortOrderDescending" : @(self.browseSortOrderDescending),
        @"browseSortFoldersSeparately" : @(self.browseSortFoldersSeparately),
        @"browseItemSubtitleField" : @(self.browseItemSubtitleField),
        @"immediateSearchOnBrowse" : @(self.immediateSearchOnBrowse),
        @"hideTotpInBrowse" : @(self.hideTotpInBrowse),
        @"showKeePass1BackupGroup" : @(self.showKeePass1BackupGroup),
        @"showChildCountOnFolderInBrowse" : @(self.showChildCountOnFolderInBrowse),
        @"showFlagsInBrowse" : @(self.showFlagsInBrowse),
        @"doNotShowRecycleBinInBrowse" : @(self.doNotShowRecycleBinInBrowse),
        @"showRecycleBinInSearchResults" : @(self.showRecycleBinInSearchResults),


        @"showEmptyFieldsInDetailsView" : @(self.showEmptyFieldsInDetailsView),
        @"easyReadFontForAll" : @(self.easyReadFontForAll),
        @"hideTotp" : @(self.hideTotp),
        @"tryDownloadFavIconForNewRecord" : @(self.tryDownloadFavIconForNewRecord),
        @"showPasswordByDefaultOnEditScreen" : @(self.showPasswordByDefaultOnEditScreen),
        @"showExpiredInBrowse" : @(self.showExpiredInBrowse),
        @"showExpiredInSearch" : @(self.showExpiredInSearch),
        @"showQuickViewFavourites" : @(self.showQuickViewFavourites),
        @"showQuickViewNearlyExpired" : @(self.showQuickViewNearlyExpired),
        @"makeBackups" : @(self.makeBackups),
        @"maxBackupKeepCount" : @(self.maxBackupKeepCount),
        @"hideTotpCustomFieldsInViewMode" : @(self.hideTotpCustomFieldsInViewMode),
        @"hideIconInBrowse" : @(self.hideIconInBrowse),
        @"tapAction" : @(self.tapAction),
        @"doubleTapAction" : @(self.doubleTapAction),
        @"tripleTapAction" : @(self.tripleTapAction),
        @"longPressTapAction" : @(self.longPressTapAction),
        @"colorizePasswords" : @(self.colorizePasswords),
        @"keePassIconSet" : @(self.keePassIconSet),
        @"isTouchIdEnabled" : @(self.isTouchIdEnabled),
        @"isEnrolledForConvenience" : @(self.isEnrolledForConvenience),
        @"hasUnresolvedConflicts" : @(self.hasUnresolvedConflicts),
        @"readOnly" : @(self.readOnly),
        @"hasBeenPromptedForConvenience" : @(self.hasBeenPromptedForConvenience),
        @"hasBeenPromptedForQuickLaunch" : @(self.hasBeenPromptedForQuickLaunch),
        @"showQuickViewExpired" : @(self.showQuickViewExpired),
        @"colorizeProtectedCustomFields" : @(self.colorizeProtectedCustomFields),
        @"promptedForAutoFetchFavIcon" : @(self.promptedForAutoFetchFavIcon),
        @"storageProvider" : @(self.storageProvider),
        @"duressAction" : @(self.duressAction),
        @"conflictResolutionStrategy" : @(self.conflictResolutionStrategy),
        @"quickTypeEnabled" : @(self.quickTypeEnabled),
        @"quickTypeDisplayFormat" : @(self.quickTypeDisplayFormat),
        @"emptyOrNilPwPreferNilCheckFirst" : @(self.emptyOrNilPwPreferNilCheckFirst),
        @"autoLockOnDeviceLock" : @(self.autoLockOnDeviceLock),
        @"autoFillConvenienceAutoUnlockTimeout" : @(self.autoFillConvenienceAutoUnlockTimeout),
        @"autoFillCopyTotp" : @(self.autoFillCopyTotp),
        @"forceOpenOffline" : @(self.forceOpenOffline),
        @"offlineDetectedBehaviour" : @(self.offlineDetectedBehaviour),
        @"couldNotConnectBehaviour" : @(self.couldNotConnectBehaviour),
        @"convenienceExpiryPeriod" : @(self.convenienceExpiryPeriod),
        @"showConvenienceExpiryMessage" : @(self.showConvenienceExpiryMessage),
        @"hasShownInitialOnboardingScreen" : @(self.hasShownInitialOnboardingScreen),
        @"convenienceExpiryOnboardingDone" : @(self.convenienceExpiryOnboardingDone),
        @"autoFillOnboardingDone" : @(self.autoFillOnboardingDone),
        @"hasAcknowledgedAppLockBiometricQuickLaunchCoalesceIssue" : @(self.hasAcknowledgedAppLockBiometricQuickLaunchCoalesceIssue),
        @"onboardingDoneHasBeenShown" : @(self.onboardingDoneHasBeenShown),
        @"scheduledExport" : @(self.scheduledExport),
        @"scheduledExportOnboardingDone" : @(self.scheduledExportOnboardingDone),
        @"scheduleExportIntervalDays" : @(self.scheduleExportIntervalDays),
        @"lockEvenIfEditing" : @(self.lockEvenIfEditing),
        @"unlockCount" : @(self.unlockCount),
        @"autoFillScanNotes" : @(self.autoFillScanNotes),
        @"autoFillScanCustomFields" : @(self.autoFillScanCustomFields),
        @"autoFillScanAltUrls" : @(self.autoFillScanAltUrls),
    }];
    
    if (self.nickName != nil) {
        ret[@"nickName"] = self.nickName;
    }
    if (self.fileName != nil) {
        ret[@"fileName"] = self.fileName;
    }
    if (self.fileIdentifier != nil) {
        ret[@"fileIdentifier"] = self.fileIdentifier;
    }
    if (self.keyFileBookmark != nil) {
        ret[@"keyFileBookmark"] = self.keyFileBookmark;
    }
    if (self.autoLockTimeoutSeconds != nil) {
        ret[@"autoLockTimeoutSeconds"] = self.autoLockTimeoutSeconds;
    }
    if (self.detailsViewCollapsedSections != nil) {
        ret[@"detailsViewCollapsedSections"] = self.detailsViewCollapsedSections;
    }
    
    if (self.yubiKeyConfig != nil) {
        ret[@"yubiKeyConfig"] = [self.yubiKeyConfig getJsonSerializationDictionary];
    }

    if (self.autoFillYubiKeyConfig != nil) {
        ret[@"autoFillYubiKeyConfig"] = [self.autoFillYubiKeyConfig getJsonSerializationDictionary];
    }

    if (self.auditConfig != nil) {
        ret[@"auditConfig"] = [self.auditConfig getJsonSerializationDictionary];
    }

    if (self.outstandingUpdateId != nil) {
        ret[@"outstandingUpdateId"] = self.outstandingUpdateId.UUIDString;
    }
    
    if (self.lastSyncRemoteModDate != nil) {
        ret[@"lastSyncRemoteModDate"] = @(self.lastSyncRemoteModDate.timeIntervalSinceReferenceDate);
    }

    if (self.lastSyncAttempt != nil) {
        ret[@"lastSyncAttempt"] = @(self.lastSyncAttempt.timeIntervalSinceReferenceDate);
    }

    if (self.autoFillLastUnlockedAt != nil) {
        ret[@"autoFillLastUnlockedAt"] = @(self.autoFillLastUnlockedAt.timeIntervalSinceReferenceDate);
    }

    if (self.nextScheduledExport != nil) {
        ret[@"nextScheduledExport"] = @(self.nextScheduledExport.timeIntervalSinceReferenceDate);
    }
    
    if (self.lastScheduledExportModDate != nil) {
        ret[@"lastScheduledExportModDate"] = @(self.lastScheduledExportModDate.timeIntervalSinceReferenceDate);
    }

    if (self.databaseCreated != nil) {
        ret[@"databaseCreated"] = @(self.databaseCreated.timeIntervalSinceReferenceDate);
    }

    return ret;
}



- (NSArray<NSString *> *)auditExcludedItems {
    NSString *key = [NSString stringWithFormat:@"%@-auditExcludedItems", self.uuid];
    
    NSArray<NSString *>* ret = [SecretStore.sharedInstance getSecureObject:key];
    
    return ret ? ret : @[];
}

- (void)setAuditExcludedItems:(NSArray<NSString *> *)auditExcludedItems {
    NSString *key = [NSString stringWithFormat:@"%@-auditExcludedItems", self.uuid];
    
    if(auditExcludedItems) {
        [SecretStore.sharedInstance setSecureObject:auditExcludedItems forIdentifier:key];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
    }
}

- (NSArray<NSString *> *)favourites {
    NSString *key = [NSString stringWithFormat:@"%@-favourites", self.uuid];
    
    NSArray<NSString *>* ret = [SecretStore.sharedInstance getSecureObject:key];
    
    return ret ? ret : @[];
}

- (void)setFavourites:(NSArray<NSString *> *)favourites {
    NSString *key = [NSString stringWithFormat:@"%@-favourites", self.uuid];
    
    if(favourites) {
        [SecretStore.sharedInstance setSecureObject:favourites forIdentifier:key];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
    }
}


- (NSString *)convenienceMasterPassword {
    BOOL expired = NO;
    NSString* object = (NSString*)[SecretStore.sharedInstance getSecureObject:self.uuid expired:&expired];
    
    if ( expired ) { 
        self.conveniencePasswordHasExpired = YES;
    }
    
    return object; 
}

- (void)setConvenienceMasterPassword:(NSString *)convenienceMasterPassword {
    NSInteger expiringAfterHours = self.convenienceExpiryPeriod;
    

    if ( self.conveniencePasswordHasExpired ) {
        self.conveniencePasswordHasExpired = NO;
    }

    if(expiringAfterHours == -1) {
        [SecretStore.sharedInstance setSecureString:convenienceMasterPassword forIdentifier:self.uuid];
    }
    else if(expiringAfterHours == 0) {
        [SecretStore.sharedInstance setSecureEphemeralObject:convenienceMasterPassword forIdentifer:self.uuid];
    }
    else {
        NSCalendar *cal = [NSCalendar currentCalendar];
        
        NSDate *date = [cal dateByAddingUnit:NSCalendarUnitHour value:expiringAfterHours toDate:[NSDate date] options:0];

        [SecretStore.sharedInstance setSecureObject:convenienceMasterPassword forIdentifier:self.uuid expiresAt:date];
    }
}

- (BOOL)conveniencePasswordHasExpired {
    NSString *key = [NSString stringWithFormat:@"%@-pw-has-expired", self.uuid];
    return [AppPreferences.sharedInstance.sharedAppGroupDefaults boolForKey:key];
}

- (void)setConveniencePasswordHasExpired:(BOOL)conveniencePasswordHasExpired {
    NSString *key = [NSString stringWithFormat:@"%@-pw-has-expired", self.uuid];
    [AppPreferences.sharedInstance.sharedAppGroupDefaults setBool:conveniencePasswordHasExpired forKey:key];
}

- (NSString *)autoFillConvenienceAutoUnlockPassword {
    NSString *key = [NSString stringWithFormat:@"%@-autoFillConvenienceAutoUnlockPassword", self.uuid];

    if( self.autoFillConvenienceAutoUnlockTimeout > 0 ) {
        return [SecretStore.sharedInstance getSecureString:key];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
        return nil;
    }
}

- (void)setAutoFillConvenienceAutoUnlockPassword:(NSString *)autoFillConvenienceAutoUnlockPassword {
    NSString *key = [NSString stringWithFormat:@"%@-autoFillConvenienceAutoUnlockPassword", self.uuid];

    if(self.autoFillConvenienceAutoUnlockTimeout > 0 && autoFillConvenienceAutoUnlockPassword) {
        NSDate* expiry = [NSDate.date dateByAddingTimeInterval:self.autoFillConvenienceAutoUnlockTimeout];
        
        NSLog(@"Setting AutoFIll convenience auto unlock expiry to: [%@]", expiry);
        
        [SecretStore.sharedInstance setSecureObject:autoFillConvenienceAutoUnlockPassword forIdentifier:key expiresAt:expiry];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
    }
}

- (NSString *)conveniencePin {
    NSString *key = [NSString stringWithFormat:@"%@-convenience-pin", self.uuid];
    return [SecretStore.sharedInstance getSecureString:key];
}

- (void)setConveniencePin:(NSString *)conveniencePin {
    NSString *key = [NSString stringWithFormat:@"%@-convenience-pin", self.uuid];

    if ( conveniencePin ) {
        [SecretStore.sharedInstance setSecureString:conveniencePin forIdentifier:key];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
    }
}

- (NSString *)duressPin {
    NSString *key = [NSString stringWithFormat:@"%@-duress-pin", self.uuid];
    return [SecretStore.sharedInstance getSecureString:key];
}

-(void)setDuressPin:(NSString *)duressPin {
    NSString *key = [NSString stringWithFormat:@"%@-duress-pin", self.uuid];
    
    if(duressPin) {
        [SecretStore.sharedInstance setSecureString:duressPin forIdentifier:key];
    }
    else {
        [SecretStore.sharedInstance deleteSecureItem:key];
    }
}

- (void)clearKeychainItems {
    self.convenienceMasterPassword = nil;
    self.autoFillConvenienceAutoUnlockPassword = nil;
    self.favourites = nil;
    self.duressPin = nil;
    self.conveniencePin = nil;
}

- (NSURL *)backupsDirectory {
    NSURL* url = [FileManager.sharedInstance.backupFilesDirectory URLByAppendingPathComponent:self.uuid isDirectory:YES];
    
    [FileManager.sharedInstance createIfNecessary:url];
    
    return url;
}

- (YubiKeyHardwareConfiguration *)contextAwareYubiKeyConfig {
#ifndef IS_APP_EXTENSION
    return self.yubiKeyConfig;
#else
    return self.autoFillYubiKeyConfig;
#endif
}

- (BOOL)mainAppAndAutoFillYubiKeyConfigsIncoherent {
    BOOL mainAppUsesYubiKey = self.yubiKeyConfig != nil && self.yubiKeyConfig.mode != kNoYubiKey;
    BOOL autoFillUsesYubiKey = self.autoFillYubiKeyConfig != nil && self.yubiKeyConfig.mode != kNoYubiKey;

    return !(!mainAppUsesYubiKey && !autoFillUsesYubiKey) && !(mainAppUsesYubiKey && autoFillUsesYubiKey);
}

- (void)setContextAwareYubiKeyConfig:(YubiKeyHardwareConfiguration *)contextAwareYubiKeyConfig {
#ifndef IS_APP_EXTENSION
    self.yubiKeyConfig = contextAwareYubiKeyConfig;
#else
    self.autoFillYubiKeyConfig = contextAwareYubiKeyConfig;
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ [%lu] - [%@-%@]", self.nickName, (unsigned long)self.storageProvider, self.fileName, self.fileIdentifier];
}

@end
