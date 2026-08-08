# 需求实施计划

- [ ] 1. 增加视觉风格状态与主题数据
  - [ ] 1.1 在 `theme_provider.dart` 增加 `AppVisualStyle`、默认 Pure Flat、持久化和容错加载，覆盖需求 1 与需求 2
  - [ ] 1.2 在 `app_theme.dart` 按视觉风格生成 Pure Flat 不透明主题和 Liquid Glass 现有主题，覆盖需求 5
  - [ ] 1.3 为默认值、独立 `copyWith`、加载和持久化增加单元测试，覆盖需求 6.1 与 6.4

- [ ] 2. 分离页面级渲染路径
  - [ ] 2.1 重构 `MainScaffold`，在 Pure Flat 使用 Material Scaffold 和 NavigationBar，在 Liquid Glass 保留现有实现，覆盖需求 3.1 与需求 4.1
  - [ ] 2.2 重构 `AppBackground`，在 Pure Flat 显示无模糊原图并跳过 LiquidGlassView 与 BackdropFilter，覆盖需求 3.3、3.5 与 3.7
  - [ ] 2.3 增加页面级 Widget 测试，验证两种风格的组件类型隔离，覆盖需求 6.2 与 6.3

- [ ] 3. 使共享控件支持双渲染路径
  - [ ] 3.1 为 AppCard、AppListTile、AppGlassIconButton 和 AppLiquidGlassSurface 增加 Pure Flat Material 分支，覆盖需求 3.2、3.6 与需求 5
  - [ ] 3.2 为输入、Toggle、Button、Chip 和 Dialog Actions 增加 Pure Flat Material 分支，覆盖需求 3.2 与需求 5
  - [ ] 3.3 增加共享控件 Widget 测试，验证 Pure Flat 子树无 liquid_glass_easy 控件且 Liquid Glass 保留原路径，覆盖需求 6.2 与 6.3

- [ ] 4. 完成主题设置和直接调用迁移
  - [ ] 4.1 在 Theme Settings 增加视觉风格选择并保持 Color Mode 独立，覆盖需求 2
  - [ ] 4.2 让背景图片支持两种风格，并仅在 Liquid Glass 显示模糊强度，覆盖需求 3.7 与需求 4.2
  - [ ] 4.3 将 Theme Settings、Local Notification Settings 和 App Lock Settings 的直接 LiquidGlass 控件迁移到共享风格感知组件，覆盖需求 3.4
  - [ ] 4.4 增加主题设置 Widget 测试，验证切换、持久化和专属设置显隐，覆盖需求 6.4

- [ ] 5. 检查点
  - [ ] 5.1 执行格式检查、静态分析和完整测试，确保所有测试通过
  - [ ] 5.2 执行 Android Release APK 与 iOS 无签名 Release 构建，覆盖需求 6.5
