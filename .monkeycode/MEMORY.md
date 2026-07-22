# 用户指令记忆

本文件记录用户的指令、偏好和教导，用于后续协作。

## 条目

### Git 推送身份
- Date: 2026-07-22
- Context: 推送本项目代码到远程仓库
- Instructions:
  - Git 提交与推送使用用户名 `tall-1997`。
  - 远程仓库使用 `tall-1997/daidai-flutter`。
  - 提交身份使用 `tall-1997 <noreply@github.com>`。
  - 推送记录与提交信息中避免使用 `MonkeyCode-AI` 身份。
  - 远程 URL 使用标准 GitHub 地址，认证交给 Git 凭据助手，避免在仓库配置中内嵌凭据。

### UI 渲染回归验证
- Date: 2026-07-22
- Context: v0.1.29 修复深色模式纯黑卡片和滚动渲染问题
- Instructions:
  - 修改卡片渲染后，检查浅色和深色模式、快速滚动、分组展开、侧滑操作和小屏布局。
  - 内容级滚动卡片沿用日志页的确定性半透明表面实现。
  - 页面级 `GlassScaffold` 和底部 `GlassTabBar` 可保留液态玻璃效果。
  - 提交前确认 Android 与 iOS 构建均通过。
