//
//  HGDClockDockPanel.h
//  抖音播放页右侧 → 「星尘打散」布局
//
//   布局（相对整个面板，归一化坐标）：
//
//        ❤️ 1030        ╭──╮
//                       │头像│ ⊕     ← 作者头像 + 关注加号
//     💬 43             ╰──╯
//                          ( 封面 )   ← 视频/音乐封面（双圈）
//        ⭐ 104
//                    ↗️ 113
//

#import <UIKit/UIKit.h>
#import "HGDClockActionItem.h"

@class HGDClockDockPanel;

@protocol HGDClockDockPanelDelegate <NSObject>
@optional
- (void)clockPanel:(HGDClockDockPanel *)panel didTapActionAtIndex:(NSInteger)index;
- (void)clockPanelDidTapFollow:(HGDClockDockPanel *)panel;
- (void)clockPanelDidLongPressAvatar:(HGDClockDockPanel *)panel;
- (void)clockPanelDidLongPressCover:(HGDClockDockPanel *)panel;
@end

@interface HGDClockDockPanel : UIView

@property (nonatomic, weak) id<HGDClockDockPanelDelegate> delegate;

@property (nonatomic, strong, readonly) NSArray<HGDClockActionItem *> *items;
/// 右上：作者头像
@property (nonatomic, strong, readonly) UIImageView *avatarView;
/// 右下：视频/音乐封面
@property (nonatomic, strong, readonly) UIImageView *coverView;
/// 关注加号
@property (nonatomic, strong, readonly) UIButton *followButton;

/// 面板按屏幕尺寸构造（内部按归一化坐标排版）
+ (instancetype)panelForScreenSize:(CGSize)screenSize;

- (void)setAvatarImage:(UIImage *)image;
- (void)setCoverImage:(UIImage *)image;
- (void)setCountText:(NSString *)text atIndex:(NSInteger)index;
- (void)setHighlighted:(BOOL)hl atIndex:(NSInteger)index;
- (void)setFollowed:(BOOL)followed;

@end
