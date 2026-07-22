# 统一液态玻璃控件设计

Feature Name: unified-liquid-glass-controls
Updated: 2026-07-22

## 设计说明

底部导航栏继续使用 `GlassTabBar` 的真实液态玻璃渲染。滚动内容中的按钮、搜索框、Chip 和选项卡片使用确定性液态玻璃视觉，避免逐控件背景采样引发纯黑块、彩虹条和快速滚动透明。

## 架构

- `AppColors` 定义浅色和深色控件表面状态。
- `ThemeData` 统一标准 Material 控件。
- `appGlassDecoration` 统一自定义控件和内容卡片。
- `AppGlassIconButton` 统一页头图标按钮。
- 页面级 `GlassScaffold` 与 `GlassTabBar` 继续提供真实玻璃氛围。

## 组件接口

- `AppCard`：内容卡片和选项卡片。
- `AppGlassIconButton`：页头新增、发送和快捷操作。
- `InputDecorationTheme`：搜索框和表单输入。
- `FilledButtonThemeData`：主要操作按钮。
- `OutlinedButtonThemeData`：次要操作按钮。
- `TextButtonThemeData`：文字操作按钮。
- `ChipThemeData`：ChoiceChip、FilterChip、ActionChip 和 InputChip。
- `TabBarThemeData`：页面选项卡。

## 正确性约束

- 内容代码中保持 `GlassCard(` 搜索结果为空。
- 滚动列表项中不使用 `BackdropFilter`。
- 危险操作保留红色前景语义。
- 主要操作保留 Emerald 前景语义。
- 所有圆角玻璃控件使用裁剪或 Material 形状限制绘制范围。

## 测试策略

- 浅色和深色模式逐页检查。
- 快速滚动任务、日志、变量、依赖、用户和通知列表。
- 检查页头按钮、搜索框、Chip、主题模式和批量按钮。
- 检查 320dp 窄屏和较大字体。
- 构建 Android Release APK。
- 构建 iOS Release IPA。
