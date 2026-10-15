//
//  HGDClockActionItem.h
//  单个互动项：深色圆底 + 白色描边图标 + 下方数字
//
//    ╭──────╮
//    │  ♡   │   ← 深灰圆底(62pt) + 白色描边图标
//    ╰──────╯
//      1030      ← 数字在圆下方
//

#import <UIKit/UIKit.h>

@interface HGDClockActionItem : UIView

/// 圆底视图（可加高光）
@property (nonatomic, strong, readonly) UIView      *circleView;
/// 图标
@property (nonatomic, strong, readonly) UIImageView *iconView;
/// 下方计数
@property (nonatomic, strong, readonly) UILabel     *countLabel;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL highlighted;

/// 圆底直径（默认 62）
@property (nonatomic, assign) CGFloat circleDiameter;

- (instancetype)initWithSymbolName:(NSString *)symbol index:(NSInteger)index;
- (void)setCount:(NSString *)countText;
@property (nonatomic, copy) void (^onTap)(NSInteger index);

@end
