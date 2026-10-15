//
//  HGDClockCommon.h
//  公共常量 / 偏好设置 / 日志
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString * const kHGDClockPrefsDomain;

/// 总开关
FOUNDATION_EXPORT BOOL HGDClockEnabled(void);
/// 是否显示数字（互动计数）
FOUNDATION_EXPORT BOOL HGDClockShowsCounts(void);
/// 星尘粒子背景
FOUNDATION_EXPORT BOOL HGDClockShowsStarfield(void);

#ifdef DEBUG
    #define HGDLog(fmt, ...) NSLog(@"[ClockDock] " fmt, ##__VA_ARGS__)
#else
    #define HGDLog(fmt, ...) do {} while (0)
#endif
