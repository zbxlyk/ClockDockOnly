//
//  HGDClockDockPanel.m
//  固定归一化坐标布局（按参考图量取）
//

#import "HGDClockDockPanel.h"
#import "HGDClockCommon.h"
#import "HGDClockStarfield.h"

// ---- 归一化坐标（相对屏幕宽/高）----
// 注：参考图是被裁切的局部截图，这里按「最右元素贴右边 10pt」重新标定
static const CGFloat kPosAction[4][2] = {   // 0评论 1点赞 2收藏 3转发
    { 0.132, 0.473 },   // 评论
    { 0.321, 0.260 },   // 点赞
    { 0.342, 0.695 },   // 收藏
    { 0.740, 0.777 },   // 转发
};
static const CGFloat kAvatarPos[2] = { 0.778, 0.211 };
static const CGFloat kCoverPos[2]  = { 0.783, 0.478 };
static const CGFloat kFollowPos[2] = { 0.750, 0.274 };

static const CGFloat kActionDiaRatio = 0.283;   // 圆底直径 / 屏幕宽
static const CGFloat kAvatarDiaRatio = 0.320;
static const CGFloat kCoverDiaRatio  = 0.382;
static const CGFloat kFollowDiaRatio = 0.160;

@interface HGDClockDockPanel ()
@property (nonatomic, assign) CGSize screenSize;
@end

@implementation HGDClockDockPanel

+ (instancetype)panelForScreenSize:(CGSize)screenSize {
    HGDClockDockPanel *p = [[self alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    p.screenSize = screenSize;
    p.backgroundColor = [UIColor clearColor];
    [p buildSubviews];
    return p;
}

- (void)buildSubviews {
    CGFloat W = _screenSize.width, H = _screenSize.height;
    CGFloat actionDia = W * kActionDiaRatio;

    // ---------- 0) 星尘背景 ----------
    if (HGDClockShowsStarfield()) {
        HGDClockStarfield *stars = [[HGDClockStarfield alloc] initWithFrame:self.bounds];
        stars.density = 1.0;
        [self addSubview:stars];
        [stars startAnimating];
    }

    // ---------- 四个互动项 ----------
    NSArray *syms = @[ @"bubble", @"heart", @"star", @"paperplane" ];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++) {
        HGDClockActionItem *it = [[HGDClockActionItem alloc] initWithSymbolName:syms[i] index:i];
        it.circleDiameter = actionDia;
        // 重建尺寸（circleDiameter 改了要重新布局）
        CGRect fr = it.frame;
        fr.size.width  = actionDia + 30.0;
        fr.size.height = actionDia + 26.0;
        it.frame = fr;
        // 让圆底重新适配
        [self resizeItem:it toDiameter:actionDia];

        it.center = CGPointMake(W * kPosAction[i][0], H * kPosAction[i][1]);
        __weak typeof(self) ws = self;
        it.onTap = ^(NSInteger idx) {
            if ([ws.delegate respondsToSelector:@selector(clockPanel:didTapActionAtIndex:)])
                [ws.delegate clockPanel:ws didTapActionAtIndex:idx];
        };
        [self addSubview:it];
        [arr addObject:it];
    }
    _items = [arr copy];

    // ---------- 作者头像（右上）----------
    CGFloat avDia = W * kAvatarDiaRatio;
    _avatarView = [self circleViewWithDiameter:avDia];
    _avatarView.center = [self clampCenter:CGPointMake(W * kAvatarPos[0], H * kAvatarPos[1])
                                    radius:avDia/2.0];
    [self addSubview:_avatarView];

    // 头像长按
    UILongPressGestureRecognizer *lp =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onAvatarLongPress:)];
    lp.minimumPressDuration = 0.6;
    _avatarView.userInteractionEnabled = YES;
    [_avatarView addGestureRecognizer:lp];

    // ---------- 视频封面（右中，双圈）----------
    CGFloat cvDia = W * kCoverDiaRatio;
    _coverView = [self doubleRingCircleViewWithDiameter:cvDia];
    // 双圈比本体大 13%，按外圈半径做边界保护
    _coverView.center = [self clampCenter:CGPointMake(W * kCoverPos[0], H * kCoverPos[1])
                                   radius:cvDia * 1.13 / 2.0];
    [self addSubview:_coverView];

    UILongPressGestureRecognizer *lp2 =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCoverLongPress:)];
    lp2.minimumPressDuration = 0.6;
    _coverView.userInteractionEnabled = YES;
    [_coverView addGestureRecognizer:lp2];

    // ---------- 关注加号（叠在头像右下）----------
    CGFloat fbDia = W * kFollowDiaRatio;
    _followButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _followButton.frame = CGRectMake(0, 0, fbDia, fbDia);
    _followButton.center = CGPointMake(W * kFollowPos[0], H * kFollowPos[1]);
    _followButton.backgroundColor = [UIColor colorWithRed:0.91 green:0.10 blue:0.32 alpha:1.0];
    _followButton.tintColor = [UIColor whiteColor];
    _followButton.layer.cornerRadius = fbDia/2.0;
    _followButton.layer.borderWidth = 2.5;
    _followButton.layer.borderColor = [UIColor blackColor].CGColor;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:fbDia*0.52
                                                            weight:UIImageSymbolWeightSemibold];
        [_followButton setImage:[UIImage systemImageNamed:@"plus" withConfiguration:cfg]
                       forState:UIControlStateNormal];
    } else {
        [_followButton setTitle:@"+" forState:UIControlStateNormal];
    }
    [_followButton addTarget:self action:@selector(onFollowTap)
            forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_followButton];
}

/// 把中心点限制在屏幕内（留 6pt 边距）
- (CGPoint)clampCenter:(CGPoint)c radius:(CGFloat)r {
    CGFloat margin = 6.0;
    CGFloat minX = margin + r, maxX = self.bounds.size.width  - margin - r;
    CGFloat minY = margin + r, maxY = self.bounds.size.height - margin - r;
    if (minX > maxX) { c.x = self.bounds.size.width / 2.0; }
    else c.x = MIN(MAX(c.x, minX), maxX);
    if (minY > maxY) { c.y = self.bounds.size.height / 2.0; }
    else c.y = MIN(MAX(c.y, minY), maxY);
    return c;
}

#pragma mark - 圆视图构造

/// 单项圆形视图（白细环）
- (UIImageView *)circleViewWithDiameter:(CGFloat)d {
    UIImageView *v = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, d, d)];
    v.contentMode = UIViewContentModeScaleAspectFill;
    v.clipsToBounds = YES;
    v.layer.cornerRadius = d/2.0;
    v.layer.borderWidth = 2.0;
    v.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.92].CGColor;
    v.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    return v;
}

/// 双圈视图（参考图右中那个金属质感双环）
- (UIImageView *)doubleRingCircleViewWithDiameter:(CGFloat)d {
    UIImageView *v = [self circleViewWithDiameter:d];
    // 外圈：在父层再加一个稍大的环
    CGFloat outer = d * 1.13;
    UIView *ring = [[UIView alloc] initWithFrame:
                    CGRectMake(-(outer-d)/2.0, -(outer-d)/2.0, outer, outer)];
    ring.userInteractionEnabled = NO;
    ring.backgroundColor = [UIColor clearColor];
    ring.layer.cornerRadius = outer/2.0;
    ring.layer.borderWidth = d * 0.075;
    ring.layer.borderColor = [UIColor colorWithWhite:0.55 alpha:0.85].CGColor;
    [v addSubview:ring];
    // 内圈亮线
    CGFloat inner = d * 0.98;
    UIView *ring2 = [[UIView alloc] initWithFrame:
                     CGRectMake((d-inner)/2.0, (d-inner)/2.0, inner, inner)];
    ring2.userInteractionEnabled = NO;
    ring2.backgroundColor = [UIColor clearColor];
    ring2.layer.cornerRadius = inner/2.0;
    ring2.layer.borderWidth = 1.0;
    ring2.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
    [v addSubview:ring2];
    return v;
}

/// 重新给 item 适配圆底直径（改尺寸后重建路径）
- (void)resizeItem:(HGDClockActionItem *)it toDiameter:(CGFloat)d {
    CGFloat w = d + 30.0, h = d + 26.0;
    it.frame = CGRectMake(it.frame.origin.x, it.frame.origin.y, w, h);
    it.circleView.frame = CGRectMake((w - d)/2.0, 0, d, d);
    it.circleView.layer.cornerRadius = d/2.0;
    for (CALayer *l in it.circleView.layer.sublayers) l.frame = it.circleView.bounds;
    if ([it.circleView.layer.sublayers.firstObject isKindOfClass:[CAGradientLayer class]])
        ((CAGradientLayer *)it.circleView.layer.sublayers.firstObject).cornerRadius = d/2.0;

    CGFloat iconSide = d * 0.46;
    it.iconView.frame = CGRectMake((w - iconSide)/2.0, (d - iconSide)/2.0, iconSide, iconSide);
    it.countLabel.frame = CGRectMake(0, d + 6.0, w, 20.0);
}

#pragma mark - 对外

- (void)setAvatarImage:(UIImage *)image { self.avatarView.image = image; }
- (void)setCoverImage:(UIImage *)image  { self.coverView.image  = image; }

- (void)setCountText:(NSString *)text atIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) return;
    [self.items[index] setCount:text];
}
- (void)setHighlighted:(BOOL)hl atIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) return;
    self.items[index].highlighted = hl;
}
- (void)setFollowed:(BOOL)followed { self.followButton.hidden = followed; }

#pragma mark - 事件

- (void)onFollowTap {
    if ([self.delegate respondsToSelector:@selector(clockPanelDidTapFollow:)])
        [self.delegate clockPanelDidTapFollow:self];
}
- (void)onAvatarLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    if ([self.delegate respondsToSelector:@selector(clockPanelDidLongPressAvatar:)])
        [self.delegate clockPanelDidLongPressAvatar:self];
}
- (void)onCoverLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    if ([self.delegate respondsToSelector:@selector(clockPanelDidLongPressCover:)])
        [self.delegate clockPanelDidLongPressCover:self];
}

@end
