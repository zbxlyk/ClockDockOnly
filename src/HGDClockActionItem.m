//
//  HGDClockActionItem.m
//  深灰圆底 + 白色描边图标 + 下方数字
//

#import "HGDClockActionItem.h"

static const CGFloat kLabelH   = 20.0;   // 数字行高
static const CGFloat kLabelGap = 6.0;    // 圆底与数字间距

@implementation HGDClockActionItem

- (instancetype)initWithSymbolName:(NSString *)symbol index:(NSInteger)index {
    _circleDiameter = 62.0;
    CGFloat w = _circleDiameter + 30.0;                 // 留出长数字宽度
    CGFloat h = _circleDiameter + kLabelGap + kLabelH;
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, h)])) {
        self.backgroundColor = [UIColor clearColor];
        _index = index;
        [self buildWithSymbol:symbol width:w];
    }
    return self;
}

- (void)buildWithSymbol:(NSString *)symbol width:(CGFloat)w {
    CGFloat d = _circleDiameter;

    // ---------- 圆底 ----------
    _circleView = [[UIView alloc] initWithFrame:CGRectMake((w - d)/2.0, 0, d, d)];
    _circleView.backgroundColor = [UIColor colorWithWhite:0.16 alpha:0.92];
    _circleView.layer.cornerRadius = d/2.0;
    _circleView.layer.borderWidth = 1.0;
    _circleView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.10].CGColor;
    _circleView.userInteractionEnabled = NO;

    // 径向渐变：中心略亮，边缘略暗（玻璃感）
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = _circleView.bounds;
    grad.type = kCAGradientLayerRadial;
    grad.colors = @[ (id)[UIColor colorWithWhite:0.28 alpha:1.0].CGColor,
                     (id)[UIColor colorWithWhite:0.13 alpha:1.0].CGColor ];
    grad.startPoint = CGPointMake(0.5, 0.38);
    grad.endPoint   = CGPointMake(1.1, 1.1);
    grad.cornerRadius = d/2.0;
    [_circleView.layer insertSublayer:grad atIndex:0];

    // 顶部高光弧
    CAShapeLayer *rim = [CAShapeLayer layer];
    rim.frame = _circleView.bounds;
    rim.fillColor = [UIColor clearColor].CGColor;
    rim.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.28].CGColor;
    rim.lineWidth = 1.5;
    rim.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(d/2, d/2) radius:d/2 - 1.0
                                           startAngle:M_PI*1.15 endAngle:M_PI*1.85
                                             clockwise:YES].CGPath;
    [_circleView.layer addSublayer:rim];
    [self addSubview:_circleView];

    // ---------- 图标（白色描边）----------
    CGFloat iconSide = d * 0.46;
    _iconView = [[UIImageView alloc] initWithFrame:
                 CGRectMake((w - iconSide)/2.0, (d - iconSide)/2.0, iconSide, iconSide)];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.tintColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:iconSide
                                                            weight:UIImageSymbolWeightLight];
        // 用**描边版**符号（非 .fill）
        _iconView.image = [UIImage systemImageNamed:symbol withConfiguration:cfg];
    }
    _iconView.userInteractionEnabled = NO;
    [self addSubview:_iconView];

    // ---------- 数字 ----------
    _countLabel = [[UILabel alloc] initWithFrame:
                   CGRectMake(0, d + kLabelGap, w, kLabelH)];
    _countLabel.textAlignment = NSTextAlignmentCenter;
    _countLabel.textColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    _countLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _countLabel.userInteractionEnabled = NO;
    [self addSubview:_countLabel];

    // ---------- 点击 ----------
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self addGestureRecognizer:tap];
    self.userInteractionEnabled = YES;
}

- (void)setCount:(NSString *)countText {
    self.countLabel.text = countText ?: @"";
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    if (highlighted) {
        self.circleView.backgroundColor = [UIColor colorWithRed:0.90 green:0.16 blue:0.35 alpha:0.95];
        self.iconView.tintColor = [UIColor whiteColor];
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:self.iconView.bounds.size.width
                                                                weight:UIImageSymbolWeightRegular];
            self.iconView.image = [UIImage systemImageNamed:[self filledSymbolName]
                                          withConfiguration:cfg];
        }
    } else {
        self.circleView.backgroundColor = [UIColor colorWithWhite:0.16 alpha:0.92];
        self.iconView.tintColor = [UIColor colorWithWhite:0.96 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:self.iconView.bounds.size.width
                                                                weight:UIImageSymbolWeightLight];
            self.iconView.image = [UIImage systemImageNamed:[self outlineSymbolName]
                                          withConfiguration:cfg];
        }
    }
}

- (NSString *)outlineSymbolName {
    NSArray *n = @[ @"bubble", @"heart", @"star", @"paperplane" ];
    return (self.index >= 0 && self.index < (NSInteger)n.count) ? n[self.index] : @"heart";
}

- (NSString *)filledSymbolName {
    NSArray *n = @[ @"bubble.fill", @"heart.fill", @"star.fill", @"paperplane.fill" ];
    return (self.index >= 0 && self.index < (NSInteger)n.count) ? n[self.index] : @"heart.fill";
}

- (void)handleTap {
    [UIView animateWithDuration:0.08 animations:^{
        self.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL f) {
        [UIView animateWithDuration:0.16 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    if (self.onTap) self.onTap(self.index);
}

@end
