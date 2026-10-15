# ClockDockOnly —— 抖音右侧互动区 → 星尘打散布局

一个**独立的**抖音越狱插件：把播放页右侧那一列互动按钮（评论 / 点赞 / 收藏 / 转发）
改造成**打散式布局** —— 深色圆底按钮散布在屏幕右侧，配作者头像、视频封面和关注加号。

```
                    ╭───╮
      ╭───╮         │头像│ ⊕
      │ ♡ │         ╰───╯
      ╰───╯            ╭─────╮
       1030            │ 封面 │   ← 双圈
                       ╰─────╯
  ╭───╮
  │ 💬│
  ╰───╯
    43
        ╭───╮
        │ ☆ │
        ╰───╯
         104      ╭───╮
                  │ ↗ │
                  ╰───╯
                    113
```

## 视觉规格

| 元素 | 直径(×屏宽) | 中心位置(x/W, y/H) | 样式 |
|---|---|---|---|
| 评论 💬 | 0.283 | 0.132, 0.473 | 深灰圆底 + 白色描边气泡 + 数字 |
| 点赞 ♡ | 0.283 | 0.321, 0.260 | 同上（点亮变玫红填充） |
| 收藏 ☆ | 0.283 | 0.342, 0.695 | 同上（点亮变玫红填充） |
| 转发 ➤ | 0.283 | 0.740, 0.777 | 同上 |
| 作者头像 | 0.320 | 0.778, 0.211 | 圆形 + 白色外环 |
| 视频封面 | 0.382 | 0.783, 0.478 | 圆形 + **双圈**金属外环 |
| 关注加号 | 0.160 | 0.750, 0.274 | 玫红 `#E81A52` + 黑描边 |

- 圆底：径向渐变 `#3A3A3A → #191919`，带顶部高光弧
- 图标：白色**描边**风格（SF Symbol 非 .fill 版），`WeightLight`
- 数字：白色 15pt Semibold，位于圆底下方 6pt
- 背景：纯黑 + **星尘粒子**（`CAEmitterLayer`，可关）

## 文件结构

```
ClockDockOnly/
├── Makefile                    Theos 构建（支持 rootful / rootless）
├── control                     deb 包信息
├── preview.html                效果预览（浏览器打开，可切换开关）
├── layout/.../ClockDockOnly.plist   注入过滤（仅抖音）
└── src/
    ├── Tweak.xm               主 Hook：定位右侧竖列 → 抓封面/头像/计数 → 挂载面板
    ├── HGDClockDockPanel.h/m  面板：固定归一化坐标布局
    ├── HGDClockActionItem.h/m 单个互动项（圆底 + 图标 + 数字）
    ├── HGDClockStarfield.h/m  星尘粒子背景
    ├── HGDClockSettings.m     偏好读写
    └── HGDClockCommon.h       公共常量 / 日志宏
```

## 编译

需要 **macOS + Theos**（iSH / Linux 编不了 iOS 目标）。

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

cd ClockDockOnly
make package                # rootful
make package ROOTLESS=1     # rootless (/var/jb, Dopamine 等)
make package install        # 直接装到设备（需 THEOS_DEVICE_IP）
```

产物：`packages/com.hgd.clockdockonly_1.0.0_iphoneos-arm64.deb`

## 安装

```bash
scp packages/*.deb root@设备IP:/var/mobile/
ssh root@设备IP "dpkg -i /var/mobile/*.deb && killall -9 Aweme"
```

或手动：把 `ClockDockOnly.dylib` + `ClockDockOnly.plist` 放进
`/Library/MobileSubstrate/DynamicLibraries/`（rootless 为 `/var/jb/Library/...`）。

## 调整

改 `src/HGDClockDockPanel.m` 顶部的 `kPosAction[]` / `kAvatarPos[]` / `kCoverPos[]`
即可调整位置；直径比例在 `k*DiaRatio`。

偏好开关（`NSUserDefaults` suite `com.hgd.clockdockonly`）：

```objc
NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"com.hgd.clockdockonly"];
[d setBool:NO forKey:@"ClockDock.Enabled"];     // 总开关
[d setBool:NO forKey:@"ClockDock.ShowsCounts"]; // 隐藏数字
[d setBool:NO forKey:@"ClockDock.Starfield"];   // 隐藏星尘
```

## 适配说明

抖音类名随版本变化，本插件**不写死类名**，运行时按特征定位：

- **右侧竖列**：宽度 < 100pt、高度 > 宽度×1.5、含 ≥3 个 UIControl
- **音乐封面**：屏幕下半部、28~80pt 的方形且含图片
- **作者头像**：屏幕上 40%、36~90pt 的方形且含图片，取最靠右的

定位不到时改 `Tweak.xm` 里对应的 `HGDFind*()` 判据。

## 已知限制

- 首次进入播放页有约 0.6~1.2s 延迟（等布局 + 封面加载）
- 抓取的是**视图快照**，若抖音用 Metal 直绘封面会失败
- 隐藏竖列后，原按钮的**长按菜单**不会转发（点击已转发）

## 免责

仅供**个人学习 / 逆向工程研究**。修改商业 App 违反其用户协议，
请勿传播或用于商业用途。
