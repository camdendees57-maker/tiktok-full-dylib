// Full TikTok dylib with TikTok-style settings panel
// Dark cards, sections, icons, chevrons. Features gated by toggles.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSUserDefaults *defaults;

static BOOL isEnabled(NSString *key) {
    return [defaults boolForKey:key];
}

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

// ---------- Settings UI (TikTok style) ----------
@interface TagtusSettingsCell : UITableViewCell
@end
@implementation TagtusSettingsCell
@end

@interface TagtusSettingsVC : UITableViewController
@end

@implementation TagtusSettingsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings and privacy";
    self.view.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"◀" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [self.tableView registerClass:[TagtusSettingsCell class] forCellReuseIdentifier:@"cell"];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 4; // Activity-style
    if (section == 1) return 3; // Account-style
    return 2; // Visibility-style
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Activity";
    if (section == 1) return @"Account";
    return @"Visibility";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TagtusSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSString *title = @"";
    NSString *key = @"";
    if (indexPath.section == 0) {
        NSArray *titles = @[@"Kill Ads", @"Force Region Unlock", @"Download / Save Videos", @"Remove Watermark"];
        NSArray *keys = @[@"killAds", @"forceRegion", @"downloadVideos", @"noWatermark"];
        title = titles[indexPath.row];
        key = keys[indexPath.row];
    } else if (indexPath.section == 1) {
        NSArray *titles = @[@"UI Tweaks (Dark / Hide)", @"Inf Coins / Gifts", @"Unlimited Gates"];
        NSArray *keys = @[@"uiTweaks", @"infCoins", @"unlimited"];
        title = titles[indexPath.row];
        key = keys[indexPath.row];
    } else {
        NSArray *titles = @[@"Extra Unlock", @"Force Premium"];
        NSArray *keys = @[@"extraUnlock", @"forcePremium"];
        title = titles[indexPath.row];
        key = keys[indexPath.row];
    }

    cell.textLabel.text = title;
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = isEnabled(key);
    sw.onTintColor = [UIColor colorWithRed:1 green:0.2 blue:0.4 alpha:1]; // TikTok pink
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    sw.tag = indexPath.section * 10 + indexPath.row;
    cell.accessoryView = sw;
    return cell;
}

- (void)switchChanged:(UISwitch *)sw {
    NSInteger section = sw.tag / 10;
    NSInteger row = sw.tag % 10;
    NSString *key = @"";
    if (section == 0) {
        NSArray *keys = @[@"killAds", @"forceRegion", @"downloadVideos", @"noWatermark"];
        key = keys[row];
    } else if (section == 1) {
        NSArray *keys = @[@"uiTweaks", @"infCoins", @"unlimited"];
        key = keys[row];
    } else {
        NSArray *keys = @[@"extraUnlock", @"forcePremium"];
        key = keys[row];
    }
    [defaults setBool:sw.on forKey:key];
    [defaults synchronize];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 52; }
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 36; }
@end

// ---------- Hooks (gated by settings) ----------
static void applyHooks(void) {
    if (isEnabled(@"killAds")) {
        NSArray *adClasses = @[@"AWEFeedAdView", @"AWECommerceView", @"AWEAdView", @"TTAdView"];
        for (NSString *name in adClasses) {
            Class c = NSClassFromString(name);
            if (!c) continue;
            safeSet(c, @selector(loadAd), (IMP)empty_void);
            safeSet(c, @selector(showAd), (IMP)empty_void);
            safeSet(c, @selector(isAd), (IMP)return_no);
            safeSet(c, @selector(shouldShowAd), (IMP)return_no);
        }
    }

    if (isEnabled(@"forceRegion") || isEnabled(@"forcePremium")) {
        Class user = NSClassFromString(@"AWEUserModel");
        safeSet(user, @selector(isVerified), (IMP)return_yes);
        Class settings = NSClassFromString(@"AWESettingsManager");
        safeSet(settings, @selector(regionLocked), (IMP)return_no);
    }

    if (isEnabled(@"downloadVideos")) {
        Class video = NSClassFromString(@"AWEAwemeModel");
        safeSet(video, @selector(canDownload), (IMP)return_yes);
    }

    if (isEnabled(@"noWatermark")) {
        Class export = NSClassFromString(@"AWEVideoExport");
        safeSet(export, @selector(addWatermark), (IMP)empty_void);
        safeSet(export, @selector(hasWatermark), (IMP)return_no);
    }

    if (isEnabled(@"infCoins")) {
        Class coins = NSClassFromString(@"AWECoinManager");
        safeSet(coins, @selector(balance), (IMP)return_big);
        safeSet(coins, @selector(coins), (IMP)return_big);
        Class gift = NSClassFromString(@"AWEGiftManager");
        safeSet(gift, @selector(sendGift:), (IMP)empty_void_id);
    }

    if (isEnabled(@"unlimited") || isEnabled(@"extraUnlock")) {
        Class obj = [NSObject class];
        const char *bigSels[] = {"coins", "balance", "credits", "points"};
        for (int i = 0; i < 4; i++) {
            SEL s = sel_registerName(bigSels[i]);
            if (class_getInstanceMethod(obj, s)) safeSet(obj, s, (IMP)return_big);
        }
    }

    NSLog(@"[Tagtus] TikTok hooks applied (settings gated)");
}

// Open settings with triple tap on status bar area or via notification
static void openSettings(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        TagtusSettingsVC *vc = [[TagtusSettingsVC alloc] initWithStyle:UITableViewStyleInsetGrouped];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:nav animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void init(void) {
    defaults = [NSUserDefaults standardUserDefaults];
    // defaults on first run
    if (![defaults objectForKey:@"killAds"]) {
        [defaults setBool:YES forKey:@"killAds"];
        [defaults setBool:YES forKey:@"forceRegion"];
        [defaults setBool:YES forKey:@"downloadVideos"];
        [defaults setBool:YES forKey:@"noWatermark"];
        [defaults setBool:YES forKey:@"infCoins"];
        [defaults setBool:YES forKey:@"unlimited"];
        [defaults synchronize];
    }

    // re-apply hooks
    for (int i = 1; i <= 5; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applyHooks();
        });
    }

    // triple tap to open settings (anywhere on screen)
    UITapGestureRecognizer *triple = [[UITapGestureRecognizer alloc] initWithTarget:nil action:NULL];
    // use a dummy and hook later if needed; for now expose via NSNotification
    [[NSNotificationCenter defaultCenter] addObserverForName:@"TagtusOpenSettings" object:nil queue:nil usingBlock:^(NSNotification *n) {
        openSettings();
    }];

    // also add a small floating button after delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, 100, 44, 44);
        btn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.9];
        btn.layer.cornerRadius = 22;
        [btn setTitle:@"⚙" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:nil action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
        // better: use a target
        objc_setAssociatedObject(btn, "open", ^{ openSettings(); }, OBJC_ASSOCIATION_COPY);
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) [win addSubview:btn];
    });
}
