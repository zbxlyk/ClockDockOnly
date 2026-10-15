//
//  HGDClockSettings.m
//  偏好读取（NSUserDefaults）
//

#import "HGDClockCommon.h"

NSString * const kHGDClockPrefsDomain = @"com.hgd.clockdockonly";

static NSUserDefaults *HGDPrefs(void) {
    return [[NSUserDefaults alloc] initWithSuiteName:kHGDClockPrefsDomain];
}
static BOOL HGDReadBool(NSString *key, BOOL dflt) {
    id v = [HGDPrefs() objectForKey:key];
    return v ? [v boolValue] : dflt;
}

BOOL HGDClockEnabled(void)       { return HGDReadBool(@"ClockDock.Enabled", YES); }
BOOL HGDClockShowsCounts(void)   { return HGDReadBool(@"ClockDock.ShowsCounts", YES); }
BOOL HGDClockShowsStarfield(void){ return HGDReadBool(@"ClockDock.Starfield", YES); }
