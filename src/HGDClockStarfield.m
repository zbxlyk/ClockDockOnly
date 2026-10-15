//
//  HGDClockStarfield.m
//  用 CAEmitterLayer 撒一层静止/微闪的星尘
//

#import "HGDClockStarfield.h"

@interface HGDClockStarfield ()
@property (nonatomic, strong) CAEmitterLayer *emitter;
@end

@implementation HGDClockStarfield

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _density = 1.0;
        _twinkles = YES;
        [self setupEmitter];
    }
    return self;
}

- (void)setupEmitter {
    _emitter = [CAEmitterLayer layer];
    _emitter.emitterShape = kCAEmitterLayerRectangle;
    _emitter.emitterMode  = kCAEmitterLayerSurface;
    _emitter.renderMode   = kCAEmitterLayerAdditive;
    [self.layer addSublayer:_emitter];

    // 造一个"星星"cell
    CAEmitterCell *star = [CAEmitterCell emitterCell];
    star.contents = (id)[self starImage].CGImage;
    star.birthRate = 0;                       // 不在时间轴上发射，改为静态铺
    star.lifetime = 1e9;
    star.velocity = 0;
    star.scale = 0.06;
    star.scaleRange = 0.04;
    star.alphaSpeed = 0;
    star.color = [UIColor whiteColor].CGColor;
    _emitter.emitterCells = @[ star ];
}

/// 画一个 4x4 的小白点（带柔边）
- (UIImage *)starImage {
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(6, 6)];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextRef c = ctx.CGContext;
        CGContextSetFillColorWithColor(c, [UIColor colorWithWhite:1.0 alpha:0.9].CGColor);
        CGContextFillEllipseInRect(c, CGRectMake(1, 1, 4, 4));
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.emitter.frame = self.bounds;
    self.emitter.emitterPosition = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.emitter.emitterSize = self.bounds.size;
    // 发射数量与面积成正比
    self.emitter.birthRate = 1;
    self.emitter.emitterCells.firstObject.birthRate =
        self.bounds.size.width * self.bounds.size.height / 9000.0 * _density;
}

- (void)startAnimating {
    if (!_twinkles) return;
    CABasicAnimation *blink = [CABasicAnimation animationWithKeyPath:@"opacity"];
    blink.fromValue = @0.35; blink.toValue = @1.0;
    blink.duration = 1.8; blink.autoreverses = YES;
    blink.repeatCount = HUGE_VALF;
    [self.emitter addAnimation:blink forKey:@"hgd.blink"];
}

- (void)stopAnimating {
    [self.emitter removeAnimationForKey:@"hgd.blink"];
}

@end
