//
//  PreferencesWindowController.m
//  Strongbox
//
//  Created by Mark on 03/04/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "Settings.h"
#import "PasswordMaker.h"
#import "MacAlerts.h"
#import "AppDelegate.h"
#import "Utils.h"
#import "NSCheckboxTableCellView.h"
#import "ColoredStringHelper.h"
#import "ClipboardManager.h"
#import "BiometricIdHelper.h"
#import "AutoFillManager.h"
#import "DatabasesManager.h"
#import "MacUrlSchemes.h"
#import "PasswordStrengthTester.h"
#import <CoreImage/CoreImage.h>
#import "Shortcut.h"

@interface PreferencesWindowController () <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSWindowDelegate>

@property (weak) IBOutlet NSButton *checkboxShowDatabasesManagerOnCloseAllWindows;

@property (weak) IBOutlet NSButton *showCustomFieldsInQuickView;
@property (weak) IBOutlet NSTableView *tableViewWordLists;
@property (weak) IBOutlet NSButton *showAttachmentsInQuickView;
@property (weak) IBOutlet NSButton *showAttachmentImagePreviewsInQuickView;

@property (weak) IBOutlet NSButton *radioBasic;
@property (weak) IBOutlet NSButton *radioXkcd;
@property (weak) IBOutlet NSButton *checkboxUseLower;
@property (weak) IBOutlet NSButton *checkboxUseUpper;
@property (weak) IBOutlet NSButton *checkboxUseDigits;
@property (weak) IBOutlet NSButton *checkboxUseSymbols;
@property (weak) IBOutlet NSButton *checkboxUseLatin1Supplement;
@property (weak) IBOutlet NSButton *checkboxUseEasy;
@property (weak) IBOutlet NSButton *checkboxNonAmbiguous;
@property (weak) IBOutlet NSButton *checkboxPickFromEveryGroup;
@property (weak) IBOutlet NSSlider *sliderPasswordLength;
@property (weak) IBOutlet NSTextField *labelPasswordLength;

@property (weak) IBOutlet NSTextField *labelXkcdWordCount;
@property (weak) IBOutlet NSStepper *stepperXkcdWordCount;
@property (weak) IBOutlet NSTextField *textFieldWordSeparator;
@property (weak) IBOutlet NSPopUpButton *popupCasing;
@property (weak) IBOutlet NSPopUpButton *popupHackerify;
@property (weak) IBOutlet NSPopUpButton *popupAddSalt;

@property (weak) IBOutlet NSTextField *labelSamplePassword;
@property (weak) IBOutlet NSTabView *tabView;

@property (weak) IBOutlet NSTextField *labelWordcount;

@property (weak) IBOutlet NSButton *checkboxShowPasswordImmediatelyInOutline;

@property (weak) IBOutlet NSSegmentedControl *segmentTitle;
@property (weak) IBOutlet NSTextField *labelCustomTitle;
@property (weak) IBOutlet NSSegmentedControl *segmentUsername;
@property (weak) IBOutlet NSTextField *labelCustomUsername;
@property (weak) IBOutlet NSSegmentedControl *segmentEmail;
@property (weak) IBOutlet NSTextField *labelCustomEmail;
@property (weak) IBOutlet NSSegmentedControl *segmentPassword;
@property (weak) IBOutlet NSTextField *labelCustomPassword;
@property (weak) IBOutlet NSSegmentedControl *segmentUrl;
@property (weak) IBOutlet NSTextField *labelCustomUrl;
@property (weak) IBOutlet NSSegmentedControl *segmentNotes;
@property (weak) IBOutlet NSTextField *labelCustomNotes;

@property NSArray<NSString*> *sortedWordListKeys;

@property (weak) IBOutlet NSButton *checkboxAutoSave;
@property (weak) IBOutlet NSButton *switchAutoClearClipboard;
@property (weak) IBOutlet NSTextField *textFieldClearClipboard;
@property (weak) IBOutlet NSStepper *stepperClearClipboard;
@property (weak) IBOutlet NSButton *switchAutoLockAfter;
@property (weak) IBOutlet NSTextField *textFieldLockDatabase;
@property (weak) IBOutlet NSStepper *stepperLockDatabase;
@property (weak) IBOutlet NSButton *switchShowInMenuBar;
@property (weak) IBOutlet NSButton *useDuckDuckGo;
@property (weak) IBOutlet NSButton *checkDomainOnly;
@property (weak) IBOutlet NSButton *useGoogle;
@property (weak) IBOutlet NSButton *scanHtml;
@property (weak) IBOutlet NSButton *ignoreSsl;
@property (weak) IBOutlet NSButton *scanCommonFiles;
@property (weak) IBOutlet NSButton *checkboxHideKeyFileName;
@property (weak) IBOutlet NSButton *checkboxDoNotRememberKeyFile;
@property (weak) IBOutlet NSButton *colorizePasswords;
@property (weak) IBOutlet NSButton *useColorBlindPalette;
@property (weak) IBOutlet NSButton *checkboxClipboardHandoff;
@property (weak) IBOutlet NSButton *buttonCopySamplePassword;
@property (weak) IBOutlet NSProgressIndicator *progressStrength;
@property (weak) IBOutlet NSTextField *labelStrength;

@property (weak) IBOutlet MASShortcutView *shortcutView;
@property (weak) IBOutlet NSButton *checkboxHideDockIconOnAllMiniaturized;

@property (weak) IBOutlet NSButton *makeRollingLocalBackups;
@property (weak) IBOutlet NSButton *hideManagerOnLaunch;
@property (weak) IBOutlet NSButton *checkboxMiniaturizeOnCopy;
@property (weak) IBOutlet NSButton *checkboxQuickRevealFields;
@property (weak) IBOutlet NSButton *checkboxEnableMarkdown;

@end

@implementation PreferencesWindowController

+ (instancetype)sharedInstance {
    static PreferencesWindowController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
    });
    
    return sharedInstance;
}

- (void)cancel:(id)sender { 
    [self close];
}

- (void)show {
    [self showWindow:nil];
}

- (void)showFavIconPreferences {
    [self show];
    [self.tabView selectTabViewItemAtIndex:3];
}

- (void)showPasswordSettings {
    [self show];
    [self.tabView selectTabViewItemAtIndex:1];
}

- (void)showGeneralSettings {
    [self show];
    [self.tabView selectTabViewItemAtIndex:0];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self setupPasswordGenerationUi];
        
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onChangePasswordParameters:)];
    [self.labelSamplePassword addGestureRecognizer:click];
    
    [self refreshSamplePassword];

    self.shortcutView.associatedUserDefaultsKey = kPreferenceGlobalShowShortcut;

    
    
    NSTabViewItem* tabViewQuickView = [self.tabView tabViewItemAtIndex:4];
    [self.tabView removeTabViewItem:tabViewQuickView];
    
    [self bindUi];
}

- (void)bindUi {
    [self bindPasswordUiToSettings];
    [self bindGeneralUiToSettings];
    [self bindAutoFillToSettings];
    [self bindAutoLockToSettings];
    [self bindAutoClearClipboard];
    [self bindFavIconDownloading];
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    if (self.window.occlusionState & NSWindowOcclusionStateVisible) {
        [self bindUi];
    }
    else
    {
        
    }
}

- (void)setupPasswordGenerationUi {
    NSDictionary<NSString*, WordList*>* wordlists = PasswordGenerationConfig.wordListsMap;
    
    self.sortedWordListKeys = [wordlists.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString* v1 = wordlists[obj1].name;
        NSString* v2 = wordlists[obj2].name;
        return finderStringCompare(v1, v2);
    }];
    
    [self.tableViewWordLists registerNib:[[NSNib alloc] initWithNibNamed:@"CheckboxCell" bundle:nil] forIdentifier:@"CheckboxCell"];
    
    self.tableViewWordLists.delegate = self;
    self.tableViewWordLists.dataSource = self;
    
    self.textFieldWordSeparator.delegate = self;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    [self onChangePasswordParameters:textField];
}

- (void)bindGeneralUiToSettings {

    
    self.checkboxAutoSave.state = Settings.sharedInstance.autoSave ? NSOnState : NSOffState;
    self.checkboxShowPasswordImmediatelyInOutline.state = Settings.sharedInstance.revealPasswordsImmediately ? NSOnState : NSOffState;

    self.showCustomFieldsInQuickView.state = Settings.sharedInstance.showCustomFieldsOnQuickViewPanel ? NSOnState : NSOffState;
    self.showAttachmentsInQuickView.state = Settings.sharedInstance.showAttachmentsOnQuickViewPanel ? NSOnState : NSOffState;
    self.showAttachmentImagePreviewsInQuickView.state = Settings.sharedInstance.showAttachmentImagePreviewsOnQuickViewPanel ? NSOnState : NSOffState;

    self.checkboxHideKeyFileName.state = Settings.sharedInstance.hideKeyFileNameOnLockScreen ? NSOnState : NSOffState;
    self.checkboxDoNotRememberKeyFile.state = Settings.sharedInstance.doNotRememberKeyFile ? NSOnState : NSOffState;
    
    self.colorizePasswords.state = Settings.sharedInstance.colorizePasswords ? NSOnState : NSOffState;
    self.useColorBlindPalette.state = Settings.sharedInstance.colorizeUseColorBlindPalette ? NSOnState : NSOffState;
    self.checkboxClipboardHandoff.state = Settings.sharedInstance.clipboardHandoff ? NSOnState : NSOffState;
    self.checkboxMiniaturizeOnCopy.state = Settings.sharedInstance.miniaturizeOnCopy ? NSOnState : NSOffState;
    self.checkboxQuickRevealFields.state = Settings.sharedInstance.quickRevealWithOptionKey ? NSOnState : NSOffState;
    
    self.checkboxShowDatabasesManagerOnCloseAllWindows.state = Settings.sharedInstance.showDatabasesManagerOnCloseAllWindows ? NSOnState : NSOffState;    
    
        
    self.switchShowInMenuBar.state = Settings.sharedInstance.showSystemTrayIcon ? NSOnState : NSOffState;
    self.checkboxHideDockIconOnAllMiniaturized.enabled = Settings.sharedInstance.showSystemTrayIcon;
    self.checkboxHideDockIconOnAllMiniaturized.state = Settings.sharedInstance.hideDockIconOnAllMinimized ? NSOnState : NSOffState;

    self.hideManagerOnLaunch.state = Settings.sharedInstance.closeManagerOnLaunch ? NSOnState : NSOffState;
    self.makeRollingLocalBackups.state = Settings.sharedInstance.makeLocalRollingBackups ? NSOnState : NSOffState;
    self.checkboxEnableMarkdown.state = Settings.sharedInstance.markdownNotes ? NSOnState : NSOffState;
}

- (IBAction)onGeneralSettingsChange:(id)sender {
    Settings.sharedInstance.revealPasswordsImmediately = self.checkboxShowPasswordImmediatelyInOutline.state == NSOnState;
    Settings.sharedInstance.autoSave = self.checkboxAutoSave.state == NSOnState;

    Settings.sharedInstance.showCustomFieldsOnQuickViewPanel = self.showCustomFieldsInQuickView.state == NSOnState;

    Settings.sharedInstance.showAttachmentsOnQuickViewPanel = self.showAttachmentsInQuickView.state == NSOnState;
    Settings.sharedInstance.showAttachmentImagePreviewsOnQuickViewPanel = self.showAttachmentImagePreviewsInQuickView.state == NSOnState;
    
    Settings.sharedInstance.hideKeyFileNameOnLockScreen = self.checkboxHideKeyFileName.state ==  NSOnState;
    Settings.sharedInstance.doNotRememberKeyFile = self.checkboxDoNotRememberKeyFile.state ==  NSOnState;

    Settings.sharedInstance.colorizePasswords = self.colorizePasswords.state == NSOnState;
    Settings.sharedInstance.colorizeUseColorBlindPalette = self.useColorBlindPalette.state == NSOnState;
    
    Settings.sharedInstance.clipboardHandoff = self.checkboxClipboardHandoff.state == NSOnState;
    Settings.sharedInstance.miniaturizeOnCopy = self.checkboxMiniaturizeOnCopy.state == NSOnState;
    Settings.sharedInstance.quickRevealWithOptionKey = self.checkboxQuickRevealFields.state == NSOnState;
    
    Settings.sharedInstance.showDatabasesManagerOnCloseAllWindows = self.checkboxShowDatabasesManagerOnCloseAllWindows.state == NSOnState;
    
    Settings.sharedInstance.showSystemTrayIcon = self.switchShowInMenuBar.state == NSOnState;
    Settings.sharedInstance.hideDockIconOnAllMinimized = self.checkboxHideDockIconOnAllMiniaturized.state == NSControlStateValueOn;
    
    Settings.sharedInstance.closeManagerOnLaunch  = self.hideManagerOnLaunch.state == NSOnState;
    
    Settings.sharedInstance.makeLocalRollingBackups = self.makeRollingLocalBackups.state == NSOnState;
    Settings.sharedInstance.markdownNotes = self.checkboxEnableMarkdown.state == NSOnState;
    
    [self bindGeneralUiToSettings];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

-(void)bindAutoFillToSettings {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;

    int index = [self autoFillModeToSegmentIndex:settings.titleAutoFillMode];
    self.segmentTitle.selectedSegment = index;
    self.labelCustomTitle.stringValue = settings.titleAutoFillMode == kCustom ? settings.titleCustomAutoFill : @"";
    
    
    
    
    index = [self autoFillModeToSegmentIndex:settings.usernameAutoFillMode];
    self.segmentUsername.selectedSegment = index;
    self.labelCustomUsername.stringValue = settings.usernameAutoFillMode == kCustom ? settings.usernameCustomAutoFill : @"";
    
    
    
    index = [self autoFillModeToSegmentIndex:settings.passwordAutoFillMode];
    self.segmentPassword.selectedSegment = index;
    self.labelCustomPassword.stringValue = settings.passwordAutoFillMode == kCustom ? settings.passwordCustomAutoFill : @"";
    
    
    
    index = [self autoFillModeToSegmentIndex:settings.emailAutoFillMode];
    self.segmentEmail.selectedSegment = index;
    self.labelCustomEmail.stringValue = settings.emailAutoFillMode == kCustom ? settings.emailCustomAutoFill : @"";
    
    
    
    index = [self autoFillModeToSegmentIndex:settings.urlAutoFillMode];
    self.segmentUrl.selectedSegment = index;
    self.labelCustomUrl.stringValue = settings.urlAutoFillMode == kCustom ? settings.urlCustomAutoFill : @"";
    
    
    
    index = [self autoFillModeToSegmentIndex:settings.notesAutoFillMode];
    self.segmentNotes.selectedSegment = index;
    self.labelCustomNotes.stringValue = settings.notesAutoFillMode == kCustom ? settings.notesCustomAutoFill : @"";
}

- (void)bindFavIconDownloading {
    FavIconDownloadOptions* options = Settings.sharedInstance.favIconDownloadOptions;

    self.useDuckDuckGo.state = options.duckDuckGo ? NSOnState : NSOffState;
    self.checkDomainOnly.state = options.domainOnly ? NSOnState : NSOffState;
    self.useGoogle.state = options.google ? NSOnState : NSOffState;
    self.scanHtml.state = options.scanHtml ? NSOnState : NSOffState;
    self.ignoreSsl.state = options.ignoreInvalidSSLCerts ? NSOnState : NSOffState;
    self.scanCommonFiles.state = options.checkCommonFavIconFiles ? NSOnState : NSOffState;
}

- (IBAction)onChangeFavIconSettings:(id)sender {
    FavIconDownloadOptions* options = Settings.sharedInstance.favIconDownloadOptions;

    options.duckDuckGo = self.useDuckDuckGo.state == NSOnState;
    options.domainOnly = self.checkDomainOnly.state == NSOnState;
    options.google = self.useGoogle.state == NSOnState;
    options.scanHtml = self.scanHtml.state == NSOnState;
    options.ignoreInvalidSSLCerts = self.ignoreSsl.state == NSOnState;
    options.checkCommonFavIconFiles = self.scanCommonFiles.state == NSOnState;

    if(options.isValid) {
        Settings.sharedInstance.favIconDownloadOptions = options;
    }
    
    [self bindFavIconDownloading];
}

















- (void)bindPasswordUiToSettings {
    PasswordGenerationConfig *params = Settings.sharedInstance.passwordGenerationConfig;

    self.radioBasic.state = params.algorithm == kPasswordGenerationAlgorithmBasic ? NSOnState : NSOffState;
    self.radioXkcd.state = params.algorithm == kPasswordGenerationAlgorithmDiceware ? NSOnState : NSOffState;

    
    
    self.checkboxUseLower.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxUseUpper.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxUseDigits.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxUseSymbols.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxUseLatin1Supplement.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxUseEasy.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxNonAmbiguous.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.checkboxPickFromEveryGroup.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.sliderPasswordLength.enabled = params.algorithm == kPasswordGenerationAlgorithmBasic;
    self.labelPasswordLength.textColor = params.algorithm == kPasswordGenerationAlgorithmBasic ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
    
    
    
    self.checkboxUseLower.state = [params.useCharacterGroups containsObject:@(kPasswordGenerationCharacterPoolLower)] ? NSOnState : NSOffState;
    self.checkboxUseUpper.state = [params.useCharacterGroups containsObject:@(kPasswordGenerationCharacterPoolUpper)] ? NSOnState : NSOffState;
    self.checkboxUseDigits.state = [params.useCharacterGroups containsObject:@(kPasswordGenerationCharacterPoolNumeric)] ? NSOnState : NSOffState;
    self.checkboxUseSymbols.state = [params.useCharacterGroups containsObject:@(kPasswordGenerationCharacterPoolSymbols)] ? NSOnState : NSOffState;
    self.checkboxUseLatin1Supplement.state = [params.useCharacterGroups containsObject:@(kPasswordGenerationCharacterPoolLatin1Supplement)] ? NSOnState : NSOffState;

    self.checkboxUseEasy.state = params.easyReadCharactersOnly ? NSOnState : NSOffState;

    self.checkboxNonAmbiguous.state = params.nonAmbiguousOnly ? NSOnState : NSOffState;
    self.checkboxPickFromEveryGroup.state = params.pickFromEveryGroup ? NSOnState : NSOffState;
    self.sliderPasswordLength.integerValue = params.basicLength;
    self.labelPasswordLength.stringValue = @(params.basicLength).stringValue;

    
    
    self.labelXkcdWordCount.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    self.labelWordcount.textColor = params.algorithm == kPasswordGenerationAlgorithmDiceware ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
    self.stepperXkcdWordCount.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    self.textFieldWordSeparator.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    self.popupCasing.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    self.popupHackerify.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    self.popupAddSalt.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    
    
    
    [self.tableViewWordLists reloadData];
    self.labelXkcdWordCount.stringValue = @(params.wordCount).stringValue;
    self.stepperXkcdWordCount.integerValue = params.wordCount;
    
    self.textFieldWordSeparator.stringValue = params.wordSeparator ? params.wordSeparator : @"";
    
    [self.popupCasing selectItem:self.popupCasing.menu.itemArray[params.wordCasing]];
    [self.popupHackerify selectItem:self.popupHackerify.menu.itemArray[params.hackerify]];
    [self.popupAddSalt selectItem:self.popupAddSalt.menu.itemArray[params.saltConfig]];
}

- (IBAction)onChangePasswordParameters:(id)sender {
    PasswordGenerationConfig *params = Settings.sharedInstance.passwordGenerationConfig;

    params.algorithm = self.radioBasic.state == NSOnState ? kPasswordGenerationAlgorithmBasic : kPasswordGenerationAlgorithmDiceware;

    
    
    NSMutableArray<NSNumber*> *newGroups = params.useCharacterGroups.mutableCopy;
    if(self.checkboxUseLower.state == NSOnState) {
        [newGroups addObject:@(kPasswordGenerationCharacterPoolLower)];
    }
    else {
        [newGroups removeObject:@(kPasswordGenerationCharacterPoolLower)];
    }

    
    
    if(self.checkboxUseUpper.state == NSOnState) {
        [newGroups addObject:@(kPasswordGenerationCharacterPoolUpper)];
    }
    else {
        [newGroups removeObject:@(kPasswordGenerationCharacterPoolUpper)];
    }

    
    
    if(self.checkboxUseDigits.state == NSOnState) {
        [newGroups addObject:@(kPasswordGenerationCharacterPoolNumeric)];
    }
    else {
        [newGroups removeObject:@(kPasswordGenerationCharacterPoolNumeric)];
    }

    
    
    if(self.checkboxUseSymbols.state == NSOnState) {
        [newGroups addObject:@(kPasswordGenerationCharacterPoolSymbols)];
    }
    else {
        [newGroups removeObject:@(kPasswordGenerationCharacterPoolSymbols)];
    }

    
    
    if(self.checkboxUseLatin1Supplement.state == NSOnState) {
        [newGroups addObject:@(kPasswordGenerationCharacterPoolLatin1Supplement)];
    }
    else {
        [newGroups removeObject:@(kPasswordGenerationCharacterPoolLatin1Supplement)];
    }
    
    params.useCharacterGroups = newGroups;

    params.easyReadCharactersOnly = self.checkboxUseEasy.state == NSOnState;
    params.nonAmbiguousOnly = self.checkboxNonAmbiguous.state == NSOnState;
    params.pickFromEveryGroup = self.checkboxPickFromEveryGroup.state == NSOnState;
    params.basicLength = self.sliderPasswordLength.integerValue;

    
    
    params.wordCount = (int)self.stepperXkcdWordCount.integerValue;
    params.wordSeparator = self.textFieldWordSeparator.stringValue;
    
    params.wordCasing = [self.popupCasing.menu.itemArray indexOfObject:self.popupCasing.selectedItem];
    params.hackerify = [self.popupHackerify.menu.itemArray indexOfObject:self.popupHackerify.selectedItem];
    params.saltConfig = [self.popupAddSalt.menu.itemArray indexOfObject:self.popupAddSalt.selectedItem];

    
    
    Settings.sharedInstance.passwordGenerationConfig = params;
    
    [self bindPasswordUiToSettings];
    [self refreshSamplePassword];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.sortedWordListKeys.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSCheckboxTableCellView *result = [tableView makeViewWithIdentifier:@"CheckboxCell" owner:self];
    
    PasswordGenerationConfig *params = Settings.sharedInstance.passwordGenerationConfig;
    NSString* wordListKey = self.sortedWordListKeys[row];
    
    result.checkbox.state = [params.wordLists containsObject:wordListKey];
    WordList* wl = PasswordGenerationConfig.wordListsMap[wordListKey];
    
    [result.checkbox setTitle:wl.name];
    
    result.onClicked = ^(BOOL checked) {
        NSLog(@"%@ - %d", wordListKey, checked);
        NSMutableArray *set = [Settings.sharedInstance.passwordGenerationConfig.wordLists mutableCopy];
        if(checked) {
            [set addObject:wordListKey];
        }
        else {
            [set removeObject:wordListKey];
        }
        
        PasswordGenerationConfig* config = Settings.sharedInstance.passwordGenerationConfig;
        config.wordLists = set;
        [Settings.sharedInstance setPasswordGenerationConfig:config];
        
        [self bindPasswordUiToSettings];
        [self refreshSamplePassword];
    };
    
    result.checkbox.enabled = params.algorithm == kPasswordGenerationAlgorithmDiceware;
    
    return result;
}



- (IBAction)onTitleSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;

    long selected = self.segmentTitle.selectedSegment;
    settings.titleAutoFillMode = selected == 0 ? kDefault : selected == 1 ? kSmartUrlFill : kCustom;
    
    if(settings.titleAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_title_default", @"Please enter your custom Title auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.titleCustomAutoFill allowEmpty:NO];

        if(response) {
            settings.titleCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

- (IBAction)onUsernameSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;
    
    long selected = self.segmentUsername.selectedSegment;
    settings.usernameAutoFillMode = selected == 0 ? kNone : selected == 1 ? kMostUsed : kCustom;
    
    if(settings.usernameAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_username_default", @"Please enter your custom Username auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.usernameCustomAutoFill allowEmpty:NO];
        
        if(response) {
            settings.usernameCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

- (IBAction)onEmailSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;
    
    long selected = self.segmentEmail.selectedSegment;
    settings.emailAutoFillMode = selected == 0 ? kNone : selected == 1 ? kMostUsed : kCustom;
    
    if(settings.emailAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_email_default", @"Please enter your custom Email auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.emailCustomAutoFill allowEmpty:NO];
        
        if(response) {
            settings.emailCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

- (IBAction)onPasswordSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;
    
    long selected = self.segmentPassword.selectedSegment;
    settings.passwordAutoFillMode = selected == 0 ? kNone : selected == 1 ? kGenerated : kCustom;
    
    if(settings.passwordAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_password_default", @"Please enter your custom Password auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.passwordCustomAutoFill allowEmpty:NO];
        
        if(response) {
            settings.passwordCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

- (IBAction)onUrlSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;
    
    long selected = self.segmentUrl.selectedSegment;
    settings.urlAutoFillMode = selected == 0 ? kNone : selected == 1 ? kSmartUrlFill : kCustom;
    
    if(settings.urlAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_url_default", @"Please enter your custom URL auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.urlCustomAutoFill allowEmpty:NO];
        
        if(response) {
            settings.urlCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

- (IBAction)onNotesSegment:(id)sender {
    AutoFillNewRecordSettings* settings = Settings.sharedInstance.autoFillNewRecordSettings;
    
    long selected = self.segmentNotes.selectedSegment;
    settings.notesAutoFillMode = selected == 0 ? kNone : selected == 1 ? kClipboard : kCustom;
    
    if(settings.notesAutoFillMode == kCustom) {
        NSString* loc = NSLocalizedString(@"mac_enter_custom_notes_default", @"Please enter your custom Notes auto fill");
        NSString* response = [[MacAlerts alloc] input:loc defaultValue:settings.notesCustomAutoFill allowEmpty:NO];
        
        if(response) {
            settings.notesCustomAutoFill = response;
        }
    }
    
    Settings.sharedInstance.autoFillNewRecordSettings = settings;
    [self bindAutoFillToSettings];
}

-(void)refreshSamplePassword {
    NSString* sample = [PasswordMaker.sharedInstance generateForConfig:Settings.sharedInstance.passwordGenerationConfig];
      
    sample = sample ? sample : @"<Could not Generate>";
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    BOOL dark = ([osxMode isEqualToString:@"Dark"]);
    BOOL colorBlind = Settings.sharedInstance.colorizeUseColorBlindPalette;
    
    NSAttributedString* str = [ColoredStringHelper getColorizedAttributedString:sample
                                                                       colorize:Settings.sharedInstance.colorizePasswords
                                                                       darkMode:dark
                                                                     colorBlind:colorBlind
                                                                           font:self.labelSamplePassword.font];
    
    NSMutableAttributedString *mut = [[NSMutableAttributedString alloc] initWithAttributedString:str];

    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    [mut addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, sample.length)];
    
    self.labelSamplePassword.attributedStringValue = mut.copy;
    
    [self bindPasswordStrength];
}

- (void)bindPasswordStrength {
    NSString* pw = self.labelSamplePassword.stringValue;
    PasswordStrength* strength = [PasswordStrengthTester getStrength:pw config:PasswordStrengthConfig.defaults];
    
    self.labelStrength.stringValue = strength.summaryString;
    
    double relativeStrength = MIN(strength.entropy / 128.0f, 1.0f); 
        
    self.progressStrength.doubleValue = relativeStrength * 100.0f;
    
    CIFilter *colorPoly = [CIFilter filterWithName:@"CIColorPolynomial"];
    [colorPoly setDefaults];
    
    double red = 1.0 - relativeStrength;
    double green = relativeStrength;

    CIVector *redVector = [CIVector vectorWithX:red Y:0 Z:0 W:0];
    CIVector *greenVector = [CIVector vectorWithX:green Y:0 Z:0 W:0];
    CIVector *blueVector = [CIVector vectorWithX:0 Y:0 Z:0 W:0];
    
    [colorPoly setValue:redVector forKey:@"inputRedCoefficients"];
    [colorPoly setValue:greenVector forKey:@"inputGreenCoefficients"];
    [colorPoly setValue:blueVector forKey:@"inputBlueCoefficients"];
    [self.progressStrength setContentFilters:@[colorPoly]];
}

- (int)autoFillModeToSegmentIndex:(AutoFillMode)mode {
    
    
    switch (mode) {
        case kNone:
        case kDefault:
            return 0;
            break;
        case kMostUsed:
        case kSmartUrlFill:
        case kClipboard:
        case kGenerated:
            return 1;
            break;
        case kCustom:
            return 2;
            break;
        default:
            NSLog(@"Ruh ROh... ");
            break;
    }
}



-(void) bindAutoLockToSettings {
    NSInteger alt = Settings.sharedInstance.autoLockTimeoutSeconds;
    
    self.switchAutoLockAfter.state = alt != 0 ? NSOnState : NSOffState;
    self.textFieldLockDatabase.enabled = alt != 0;
    self.stepperLockDatabase.enabled = alt != 0;
    self.stepperLockDatabase.integerValue = alt;
    self.textFieldLockDatabase.stringValue =  self.stepperLockDatabase.stringValue;
}

- (IBAction)onAutolockChange:(id)sender {
    NSLog(@"onAutolockChange: [%d]", self.switchAutoLockAfter.state == NSOnState);
    
    Settings.sharedInstance.autoLockTimeoutSeconds = self.switchAutoLockAfter.state == NSOnState ? 120 : 0;
    
    [self bindAutoLockToSettings];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

- (IBAction)onStepperAutoLockDatabase:(id)sender {
    Settings.sharedInstance.autoLockTimeoutSeconds =     self.stepperLockDatabase.integerValue;
    
    [self bindAutoLockToSettings];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

- (IBAction)onTextFieldAutoLockEdited:(id)sender {
    self.stepperLockDatabase.integerValue = self.textFieldLockDatabase.integerValue;
    
    Settings.sharedInstance.autoLockTimeoutSeconds =     self.stepperLockDatabase.integerValue;
    
    [self bindAutoLockToSettings];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}



- (void)bindAutoClearClipboard {
    self.switchAutoClearClipboard.state = Settings.sharedInstance.clearClipboardEnabled ? NSOnState : NSOffState;

    self.textFieldClearClipboard.enabled = Settings.sharedInstance.clearClipboardEnabled;

    self.stepperClearClipboard.enabled = Settings.sharedInstance.clearClipboardEnabled;

    self.stepperClearClipboard.integerValue = Settings.sharedInstance.clearClipboardAfterSeconds;
    
    self.textFieldClearClipboard.stringValue =  self.stepperClearClipboard.stringValue;
}

- (IBAction)onStepperClearClipboard:(id)sender {
    Settings.sharedInstance.clearClipboardAfterSeconds =     self.stepperClearClipboard.integerValue;
    
    [self bindAutoClearClipboard];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

- (IBAction)onClearClipboardTextFieldEdited:(id)sender {
    self.stepperClearClipboard.integerValue = self.textFieldClearClipboard.integerValue;
    
    
    
    Settings.sharedInstance.clearClipboardAfterSeconds =     self.stepperClearClipboard.integerValue;
    
    [self bindAutoClearClipboard];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

- (IBAction)onAutoClearClipboard:(id)sender {
    NSLog(@"onAutoClearClipboard: [%d]", self.switchAutoClearClipboard.state == NSOnState);
    
    Settings.sharedInstance.clearClipboardEnabled = self.switchAutoClearClipboard.state == NSOnState;
    
    [self bindAutoClearClipboard];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferencesChangedNotification object:nil];
}

- (IBAction)onCopyGenerated:(id)sender {
    NSAttributedString* samplePassword = self.labelSamplePassword.attributedStringValue;
    
    [ClipboardManager.sharedInstance copyConcealedString:samplePassword.string];

    NSString* loc = NSLocalizedString(@"mac_field_copied_to_clipboard_no_item_title_fmt", @"%@ Copied");
    NSString* msg= [NSString stringWithFormat:loc, NSLocalizedString(@"generic_fieldname_password", @"Password")];
    
    self.labelSamplePassword.stringValue = msg;
    self.labelSamplePassword.textColor = NSColor.systemBlueColor;
    self.buttonCopySamplePassword.enabled = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.labelSamplePassword.attributedStringValue = samplePassword;
        self.buttonCopySamplePassword.enabled = YES;
        self.labelSamplePassword.textColor = nil;
    });
}
    
- (IBAction)onClearQuickTypeAutoFillDatabase:(id)sender {
    [AutoFillManager.sharedInstance clearAutoFillQuickTypeDatabase];
}

@end
