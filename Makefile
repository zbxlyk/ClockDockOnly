# ============================================================
#  ClockDockOnly —— 抖音右侧互动区 → 星尘打散布局
#  基于 Theos
#
#  编译:   make package                    (rootful, 默认)
#         make package THEOS_PACKAGE_SCHEME=rootless   (rootless, /var/jb)
#  产物:   packages/*.deb
# ============================================================

ARCHS        = arm64e arm64
TARGET       = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClockDockOnly

ClockDockOnly_FILES = src/Tweak.xm \
                      src/HGDClockDockPanel.m \
                      src/HGDClockActionItem.m \
                      src/HGDClockStarfield.m \
                      src/HGDClockSettings.m

ClockDockOnly_CFLAGS     = -fobjc-arc -Wno-deprecated-declarations
ClockDockOnly_FRAMEWORKS = UIKit QuartzCore CoreGraphics
ClockDockOnly_LIBRARIES  = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Aweme 2>/dev/null || true"
