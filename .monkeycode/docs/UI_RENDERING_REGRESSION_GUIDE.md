# UI 渲染回归防护指南

## 背景

`v0.1.29` 修复了深色模式下内容卡片偶发纯黑块、滚动时玻璃透明、彩色边缘和离屏纹理异常问题。日志页面一直表现稳定，因此本次以日志列表卡片作为全应用内容卡片的渲染基线。

## 根因

问题来源于滚动内容中逐卡片创建 `GlassCard(useOwnLayer: true)`。即使使用 `GlassQuality.minimal`，组件仍会使用背景模糊或离屏合成。卡片进入滚动、裁剪、回收、复用或位移动画后，部分设备的 GPU 合成纹理可能显示为纯黑矩形或透明表面。

深色颜色值不是主要原因。日志页使用相同的 `AppColors.darkSurface` 和 `AppColors.darkBorder`，通过普通 `Container + BoxDecoration` 能稳定呈现蓝灰半透明表面。

## 稳定架构

- 应用根级保留 `LiquidGlassWidgets.wrap`。
- 主页面保留 `GlassScaffold`。
- 底部导航保留 `GlassTabBar`。
- 内容卡片统一使用 `AppCard`。
- `AppCard` 使用确定性的 `Container + BoxDecoration`。
- 浅色表面使用 `AppColors.lightSurface`。
- 深色表面使用 `AppColors.darkSurface`。
- 深色边框使用 `AppColors.darkBorder`。
- 滚动列表优先使用 `ListView.builder` 或 Sliver 惰性构建。
- 可位移、可排序和可复用的列表项中不放置 `BackdropFilter` 或逐项玻璃采样层。

## 禁止回归模式

内容级卡片避免重新引入以下组合：

```dart
GlassCard(
  useOwnLayer: true,
  child: ...,
)
```

尤其避免在 `ListView`、`ReorderableListView`、`Transform`、`AnimatedContainer`、`Dismissible` 或多重 `ClipRRect` 内使用逐卡片玻璃层。

## 修改范围

`v0.1.29` 将以下页面的内容卡片统一到稳定表面：

- 仪表盘和统计图表
- 定时任务与任务表单
- 环境变量
- 用户管理
- 通知渠道与本地通知
- 依赖管理
- 安全日志与会话
- OpenAPI
- 脚本管理
- 订阅管理
- 系统设置、面板设置与备份
- 应用锁
- 更多与主题设置

## 回归检查清单

每次修改卡片或背景实现后执行：

1. 浅色模式检查页面背景、卡片、输入框、Chip 和文字对比度。
2. 深色模式检查卡片保持蓝灰色层次，无纯黑矩形。
3. 快速连续上下滚动，检查卡片无透明跳变、彩虹条和残影。
4. 展开和折叠任务分组，检查卡片内容与背景稳定。
5. 测试任务侧滑、删除按钮和“更多”操作面板。
6. 使用窄屏和较大字体检查横向溢出。
7. 确认内容代码中没有新增 `GlassCard(`。
8. 执行 Android Release 构建。
9. 执行 iOS Release 无签名构建。

## 检查命令

```bash
# 内容卡片应通过 AppCard 实现
rg "GlassCard\\(" lib

# 检查差异格式
git diff --check

# 构建 Android
flutter build apk --release

# 构建 iOS
flutter build ios --release --no-codesign
```

正常情况下，`GlassCard(` 搜索结果为空；`liquid_glass_widgets` 仅用于应用根主题、页面级玻璃 Scaffold 和底部导航。
