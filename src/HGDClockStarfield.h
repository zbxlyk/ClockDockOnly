//
//  HGDClockStarfield.h
//  星尘粒子背景（参考图里的细小白点）
//

#import <UIKit/UIKit.h>

@interface HGDClockStarfield : UIView

/// 星星密度系数（默认 1.0）
@property (nonatomic, assign) CGFloat density;
/// 是否闪烁
@property (nonatomic, assign) BOOL twinkles;

- (void)startAnimating;
- (void)stopAnimating;

@end
