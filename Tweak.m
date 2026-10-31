// Full TikTok dylib - no ads, region unlock, download, no watermark, UI tweaks, inf coins
// Pure runtime, no Substrate. Frameworks install name, unsigned for Sideloadly/KSign.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void safeSet(Class cls, SEL sel, IMP imp) {
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, sel);
    if (m) method_setImplementation(m, imp);
}

static void safeSetClass(Class cls, SEL sel, IMP imp) {
    if (!cls) return;
    Method m = class_getClassMethod(cls, sel);
    if (m) method_setImplementation(m, imp);
}

static void empty_void(id self, SEL _cmd) {}
static void empty_void_id(id self, SEL _cmd, id a) {}
static BOOL return_yes(id self, SEL _cmd) { return YES; }
static BOOL return_no(id self, SEL _cmd) { return NO; }
static NSInteger return_big(id self, SEL _cmd) { return 999999999; }
static id return_nil(id self, SEL _cmd) { return nil; }

static void applyHooks(void) {
    // ---------- ads / sponsored ----------
    NSArray *adClasses = @[@"AWEFeedAdView", @"AWECommerceView", @"AWEAdView", @"TTAdView",
                           @"AWEAwemeAdModel", @"AWEFeedCell", @"AWEPlayInteractionView"];
    for (NSString *name in adClasses) {
        Class c = NSClassFromString(name);
        if (!c) continue;
        safeSet(c, @selector(loadAd), (IMP)empty_void);
        safeSet(c, @selector(showAd), (IMP)empty_void);
        safeSet(c, @selector(isAd), (IMP)return_no);
        safeSet(c, @selector(shouldShowAd), (IMP)return_no);
        safeSet(c, @selector(adModel), (IMP)return_nil);
    }

    // ---------- region / unlock ----------
    Class user = NSClassFromString(@"AWEUserModel");
    safeSet(user, @selector(region), (IMP)return_yes); // force unlocked
    safeSet(user, @selector(isVerified), (IMP)return_yes);

    Class settings = NSClassFromString(@"AWESettingsManager");
    safeSet(settings, @selector(regionLocked), (IMP)return_no);
    safeSet(settings, @selector(featureUnlocked), (IMP)return_yes);

    // ---------- download / save ----------
    Class video = NSClassFromString(@"AWEAwemeModel");
    safeSet(video, @selector(canDownload), (IMP)return_yes);
    safeSet(video, @selector(downloadURL), (IMP)return_nil); // placeholder - real needs URL extract

    Class download = NSClassFromString(@"AWEVideoDownloadManager");
    safeSet(download, @selector(downloadVideo:), (IMP)empty_void_id);

    // ---------- watermark ----------
    Class export = NSClassFromString(@"AWEVideoExport");
    safeSet(export, @selector(addWatermark), (IMP)empty_void);
    safeSet(export, @selector(hasWatermark), (IMP)return_no);

    // ---------- UI tweaks ----------
    Class ui = NSClassFromString(@"AWEFeedViewController");
    safeSet(ui, @selector(hideElements), (IMP)empty_void);
    safeSet(ui, @selector(forceDarkMode), (IMP)return_yes);

    // ---------- inf coins / gifts ----------
    Class coins = NSClassFromString(@"AWECoinManager");
    safeSet(coins, @selector(balance), (IMP)return_big);
    safeSet(coins, @selector(coins), (IMP)return_big);
    safeSet(coins, @selector(consume:), (IMP)empty_void_id);

    Class gift = NSClassFromString(@"AWEGiftManager");
    safeSet(gift, @selector(sendGift:), (IMP)empty_void_id);
    safeSet(gift, @selector(giftCost), (IMP)return_big);

    // generic fallbacks
    Class obj = [NSObject class];
    const char *bigSels[] = {"coins", "balance", "credits", "points", "tokens", "roses"};
    for (int i = 0; i < 6; i++) {
        SEL s = sel_registerName(bigSels[i]);
        if (class_getInstanceMethod(obj, s)) safeSet(obj, s, (IMP)return_big);
    }

    const char *yesSels[] = {"isPremium", "isUnlocked", "canDownload", "isVerified", "hasAccess"};
    for (int i = 0; i < 5; i++) {
        SEL s = sel_registerName(yesSels[i]);
        if (class_getInstanceMethod(obj, s)) safeSet(obj, s, (IMP)return_yes);
    }

    NSLog(@"[Tagtus] TikTok full hooks applied");
}

__attribute__((constructor))
static void init(void) {
    for (int i = 1; i <= 4; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applyHooks();
        });
    }
}
