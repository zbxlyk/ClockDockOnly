//
//  Tweak.xm
//  抖音播放页右侧互动竖列 → 「打散/星芒」布局
//    · 四个互动项（评论/点赞/收藏/转发）沿圆弧等分排列
//    · 每项带互动计数数字
//    · 中心是音乐封面 + 关注加号
//    · 白色虚线辅助线 + 青/玫红彩色连线
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "HGDClockCommon.h"
#import "HGDClockDockPanel.h"

#pragma mark - 关联 key

static const void *kHGDPanelKey  = &kHGDPanelKey;
static const void *kHGDHiddenKey = &kHGDHiddenKey;

#pragma mark - 前置声明

static UIView   *HGDFindRightActionColumn(UIView *root, int depth);
static UIView   *HGDFindMusicCover(UIView *root);
static UIView   *HGDFindAuthorAvatar(UIView *root);
static UIImage  *HGD_SnapshotView(UIView *v);
static UIButton *HGDFindButtonInColumn(UIView *column, NSInteger index);
static NSString *HGDFindCountTextNear(UIView *root, UIView *anchor);

#pragma mark - 特征判断

static BOOL HGDLooksLikeRightActionColumn(UIView *v) {
    if (!v) return NO;
    CGSize sz = v.bounds.size;
    if (sz.height < 40 || sz.width <= 0) return NO;
    if (sz.width > 100) return NO;
    if (sz.height < sz.width * 1.5) return NO;

    NSInteger controls = 0;
    for (UIView *sub in v.subviews) if ([sub isKindOfClass:[UIControl class]]) controls++;
    if (controls >= 3) return YES;

    if (v.subviews.count >= 3) {
        BOOL allSmall = YES;
        for (UIView *sub in v.subviews)
            if (sub.bounds.size.width > 70 || sub.bounds.size.height > 70) { allSmall = NO; break; }
        if (allSmall) return YES;
    }
    return NO;
}

static UIView *HGDFindRightActionColumn(UIView *root, int depth) {
    if (!root || depth > 9) return nil;
    if (HGDLooksLikeRightActionColumn(root)) return root;
    for (UIView *sub in root.subviews) {
        UIView *r = HGDFindRightActionColumn(sub, depth + 1);
        if (r) return r;
    }
    return nil;
}

/// 找底部音乐封面
static UIView *HGDFindMusicCover(UIView *root) {
    if (!root) return nil;
    CGSize screen = root.bounds.size;
    __block UIView *result = nil;
    __block CGFloat bestScore = 0;

    __block __weak void (^weakWalk)(UIView *);
    void (^walk)(UIView *);
    weakWalk = walk = ^(UIView *v) {
        if (!v) return;
        CGRect f = [v convertRect:v.bounds toView:root];
        if (f.origin.y > screen.height * 0.5 &&
            f.size.width >= 28 && f.size.width <= 80 &&
            fabs(f.size.width - f.size.height) < 12) {
            BOOL hasImage = [v isKindOfClass:[UIImageView class]];
            if (!hasImage)
                for (UIView *s in v.subviews)
                    if ([s isKindOfClass:[UIImageView class]]) { hasImage = YES; break; }
            if (hasImage && f.size.width > bestScore) { bestScore = f.size.width; result = v; }
        }
        for (UIView *s in v.subviews) if (weakWalk) weakWalk(s);
    };
    if (weakWalk) weakWalk(root);
    return result;
}

/// 视图快照
static UIImage *HGD_SnapshotView(UIView *v) {
    if (!v || v.bounds.size.width < 1 || v.bounds.size.height < 1) return nil;
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:v.bounds.size];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [v drawViewHierarchyInRect:v.bounds afterScreenUpdates:NO];
    }];
}

/// 找作者头像：屏幕上部的圆形视图（通常在最右侧）
static UIView *HGDFindAuthorAvatar(UIView *root) {
    if (!root) return nil;
    CGSize screen = root.bounds.size;
    __block UIView *result = nil;
    __block CGFloat bestScore = 0;

    __block __weak void (^weakWalk)(UIView *);
    void (^walk)(UIView *);
    weakWalk = walk = ^(UIView *v) {
        if (!v) return;
        CGRect f = [v convertRect:v.bounds toView:root];
        // 上 40% 区域、36~90pt 的近似方形
        if (f.origin.y < screen.height * 0.40 &&
            f.origin.y > screen.height * 0.02 &&
            f.size.width >= 36 && f.size.width <= 90 &&
            fabs(f.size.width - f.size.height) < 14) {
            BOOL hasImage = [v isKindOfClass:[UIImageView class]];
            if (!hasImage)
                for (UIView *s in v.subviews)
                    if ([s isKindOfClass:[UIImageView class]]) { hasImage = YES; break; }
            // 越靠右越可能是头像
            if (hasImage) {
                CGFloat score = CGRectGetMaxX(f) + f.size.width;
                if (score > bestScore) { bestScore = score; result = v; }
            }
        }
        for (UIView *s in v.subviews) if (weakWalk) weakWalk(s);
    };
    if (weakWalk) weakWalk(root);
    return result;
}

/// 在原竖列里按从上到下顺序取第 index 个可点控件
static UIButton *HGDFindButtonInColumn(UIView *column, NSInteger index) {
    if (!column) return nil;
    NSMutableArray<UIView *> *btns = [NSMutableArray array];
    __block __weak void (^weakWalk)(UIView *);
    void (^walk)(UIView *);
    weakWalk = walk = ^(UIView *v) {
        if (!v) return;
        if ([v isKindOfClass:[UIControl class]]) [btns addObject:v];
        for (UIView *s in v.subviews) if (weakWalk) weakWalk(s);
    };
    if (weakWalk) weakWalk(column);
    [btns sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        return a.frame.origin.y < b.frame.origin.y ? NSOrderedAscending : NSOrderedDescending;
    }];
    if (index >= 0 && index < (NSInteger)btns.count) return (UIButton *)btns[index];
    return (UIButton *)btns.lastObject;
}

/// 在某个按钮附近找纯数字文本（互动计数）
static NSString *HGDFindCountTextNear(UIView *root, UIView *anchor) {
    if (!root || !anchor) return nil;
    CGRect af = [anchor convertRect:anchor.bounds toView:root];
    __block NSString *best = nil;
    __block CGFloat bestDist = 90.0;   // 最多在 90pt 内找

    __block __weak void (^weakWalk)(UIView *);
    void (^walk)(UIView *);
    weakWalk = walk = ^(UIView *v) {
        if (!v) return;
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *lb = (UILabel *)v;
            NSString *t = [lb.text stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (t.length > 0 && t.length <= 8) {
                // 纯数字 / 带 k、w、万 后缀
                NSCharacterSet *num = [NSCharacterSet characterSetWithCharactersInString:
                                       @"0123456789.kw万K"];
                NSCharacterSet *other = [num invertedSet];
                if ([t rangeOfCharacterFromSet:other].location == NSNotFound) {
                    CGRect lf = [lb convertRect:lb.bounds toView:root];
                    CGFloat dx = fabs(CGRectGetMidX(lf) - CGRectGetMidX(af));
                    CGFloat dy = fabs(CGRectGetMidY(lf) - CGRectGetMidY(af));
                    CGFloat d = hypot(dx, dy);
                    if (d < bestDist) { bestDist = d; best = t; }
                }
            }
        }
        for (UIView *s in v.subviews) if (weakWalk) weakWalk(s);
    };
    if (weakWalk) weakWalk(root);
    return best;
}

#pragma mark - 协调器

@interface HGDClockCoordinator : NSObject <HGDClockDockPanelDelegate>
@property (nonatomic, weak) HGDClockDockPanel *panel;
@property (nonatomic, weak) UIView *hostView;
@property (nonatomic, weak) UIView *originalColumn;
@property (nonatomic, assign) BOOL scanning;
+ (instancetype)shared;
- (void)scanAndAttachFromWindow:(UIWindow *)window;
@end

@implementation HGDClockCoordinator

+ (instancetype)shared {
    static HGDClockCoordinator *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [HGDClockCoordinator new]; });
    return s;
}

- (void)scanAndAttachFromWindow:(UIWindow *)window {
    if (!window || !HGDClockEnabled()) return;
    if (self.scanning) return;
    self.scanning = YES;
    UIView *column = HGDFindRightActionColumn(window, 0);
    if (column) [self attachPanelToColumn:column];
    self.scanning = NO;
}

- (void)attachPanelToColumn:(UIView *)column {
    if (!column || !HGDClockEnabled()) return;
    if (objc_getAssociatedObject(column, kHGDPanelKey)) return;

    UIView *host = column.superview ?: column;
    self.hostView = host;
    self.originalColumn = column;

    // 面板铺满整个宿主（元素位置在内部按归一化坐标算）
    HGDClockDockPanel *panel = [HGDClockDockPanel panelForScreenSize:host.bounds.size];
    panel.delegate = self;
    panel.frame = host.bounds;
    panel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [host addSubview:panel];
    [host bringSubviewToFront:panel];

    // 隐藏原竖列（保留可点，由我们转发）
    column.hidden = YES;
    objc_setAssociatedObject(column, kHGDHiddenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(column, kHGDPanelKey, panel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.panel = panel;

    HGDLog(@"面板已挂载到 %@", column);

    __weak typeof(self) ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [ws refreshContent];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)onOrientationChange {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self relayoutIfNeeded];
    });
}

- (void)relayoutIfNeeded {
    if (!self.panel || !self.hostView) return;
    self.panel.frame = self.hostView.bounds;
}

/// 抓封面 + 抓头像 + 抓计数
- (void)refreshContent {
    UIView *root = self.hostView.window ?: self.hostView;

    // 1) 视频/音乐封面（右中）
    UIView *cover = HGDFindMusicCover(root);
    if (cover) {
        UIImage *snap = HGD_SnapshotView(cover);
        if (snap) [self.panel setCoverImage:snap];
    }

    // 2) 作者头像（右上）
    UIView *avatar = HGDFindAuthorAvatar(root);
    if (avatar) {
        UIImage *snap = HGD_SnapshotView(avatar);
        if (snap) [self.panel setAvatarImage:snap];
    } else if (cover) {
        [self.panel setAvatarImage:HGD_SnapshotView(cover)];
    }

    // 3) 计数（评论/点赞/收藏/转发）
    if (HGDClockShowsCounts()) {
        for (NSInteger i = 0; i < 4; i++) {
            UIButton *btn = HGDFindButtonInColumn(self.originalColumn, i);
            NSString *t = HGDFindCountTextNear(self.originalColumn.superview ?: root, btn);
            if (t) [self.panel setCountText:t atIndex:i];
        }
    }
}

#pragma mark - HGDClockDockPanelDelegate

- (void)clockPanel:(HGDClockDockPanel *)panel didTapActionAtIndex:(NSInteger)index {
    UIButton *origin = HGDFindButtonInColumn(self.originalColumn, index);
    if (origin) [origin sendActionsForControlEvents:UIControlEventTouchUpInside];
    else HGDLog(@"未找到原始按钮 index=%ld", (long)index);

    // 点赞/收藏：立即取反高亮
    if (index == 1 || index == 2) {
        HGDClockActionItem *it = panel.items[index];
        [panel setHighlighted:!it.highlighted atIndex:index];
    }
}

- (void)clockPanelDidTapFollow:(HGDClockDockPanel *)panel {
    // 抖音的关注按钮通常在头像下方，取竖列第一个按钮的长按/点击
    UIButton *first = HGDFindButtonInColumn(self.originalColumn, 0);
    if (first) [first sendActionsForControlEvents:UIControlEventTouchUpInside];
    [panel setFollowed:YES];
}

- (void)clockPanelDidLongPressCover:(HGDClockDockPanel *)panel {
    HGDLog(@"长按封面 → 预留设置入口");
}

@end

#pragma mark - 动态 Hook

static void (*orig_viewDidAppear)(id, SEL, BOOL);

static void hgd_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    if (orig_viewDidAppear) orig_viewDidAppear(self, _cmd, animated);
    if (!HGDClockEnabled()) return;

    NSString *cls = NSStringFromClass([self class]);
    if (![cls containsString:@"PlayInteraction"] &&
        ![cls containsString:@"Feed"] &&
        ![cls containsString:@"Aweme"]) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if ([self isKindOfClass:[UIViewController class]])
            win = [(UIViewController *)self view].window;
        [[HGDClockCoordinator shared] scanAndAttachFromWindow:win];
    });
}

%ctor {
    @autoreleasepool {
        HGDLog(@"ClockDockOnly loaded v2.0.0 (scatter layout)");
        MSHookMessageEx(objc_getClass("UIViewController"),
                        @selector(viewDidAppear:),
                        (IMP)&hgd_viewDidAppear,
                        (IMP *)&orig_viewDidAppear);
    }
}
