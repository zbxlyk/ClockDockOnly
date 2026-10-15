# ============================================================
#  ClockDockOnly —— 抖音右侧竖列 → 时钟表盘 (独立 dylib)
#  基于 Theos
#
#  编译:   make package           (rootful, 默认)
#         make package ROOTLESS=1 (rootless, /var/jb)
#  产物:   packages/*.deb  以及  .theos/obj/ClockDockOnly.dylib
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

ClockDockOnly_CFLAGS  = -fobjc-arc -Wno-deprecated-declarations
ClockDockOnly_FRAMEWORKS = UIKit QuartzCore CoreGraphics
ClockDockOnly_PRIVATE_FRAMEWORKS =
ClockDockOnly_LIBRARIES = substrate
ClockDockOnly_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk

# ---- rootless (/var/jb) 支持 ----
ifeq ($(ROOTLESS),1)
    ClockDockOnly_CFLAGS += -DTHEOS_ROOTLESS
    ClockDockOnly_INSTALL_PATH = /var/jb/Library/MobileSubstrate/DynamicLibraries
    TARGET = iphone:clang:latest:15.0
endif

after-install::
	install.exec "killall -9 Aweme 2>/dev/null || true"
