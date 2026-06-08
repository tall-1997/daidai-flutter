<p align="center">
  <img src="./images/图标.png" alt="呆呆面板 Flutter" width="100">
</p>

<h1 align="center">呆呆面板 Flutter</h1>

<p align="center">
  <em>呆呆面板官方移动端 App，基于 Flutter 构建</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/iOS-IPA-007AFF?logo=apple&logoColor=white" alt="iOS">
  <img src="https://img.shields.io/github/v/release/tall-1997/daidai-flutter" alt="Version">
</p>

---

## 简介

呆呆面板 Flutter 是 [呆呆面板](https://github.com/linzixuanzz/daidai-panel) 的官方移动端客户端，使用 Flutter 框架开发，支持 Android 和 iOS 双平台。通过本 App，您可以随时随地管理定时任务、查看执行日志、编辑脚本、监控系统状态。

## 下载

### 最新版本 v0.0.43

| 平台 | 下载链接 |
|------|---------|
| Android APK | [daidai-flutter-v0.0.43-android.apk](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.43/daidai-flutter-v0.0.43-android.apk) |
| iOS IPA | [daidai-flutter-v0.0.43-ios.ipa](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.43/daidai-flutter-v0.0.43-ios.ipa) |

> 所有版本: [Releases](https://github.com/tall-1997/daidai-flutter/releases)

## 功能特性

### 核心功能

- **定时任务管理** — Cron 表达式调度，支持启用/禁用、手动触发、重试机制、超时控制、任务依赖、前后置钩子、并发实例控制、Python 多版本选择（3.10/3.11/3.12）
- **脚本文件管理** — 在线代码编辑器，支持语法高亮、全屏编辑、查找替换、格式化、行号显示、版本管理、调试运行
- **执行日志** — SSE 实时日志流，历史日志查看，状态追踪（成功/失败/超时/手动终止），日志统计与清理
- **环境变量** — 分组管理、拖拽排序、批量导入导出（兼容青龙格式）、变量值脱敏显示
- **依赖管理** — 可视化安装/卸载 Python (pip) 和 Node.js (npm) 依赖，支持按 Python 版本（3.10/3.11/3.12）筛选和管理

### 系统管理

- **系统监控** — 实时 CPU / 内存 / 磁盘监控，趋势图表展示（每5秒采样）
- **系统安全** — 双因素认证 (2FA)、IP 白名单、登录日志、多设备会话管理
- **配置管理** — 面板标题与图标自定义、通知渠道配置、备份与恢复
- **通知推送** — 支持 18 种推送渠道

### 支持的通知渠道

| 类型 | 渠道 |
|------|------|
| 即时通讯 | 企业微信、钉钉、飞书、Telegram、Discord、Slack |
| 推送服务 | Bark、PushPlus、Server酱、PushDeer、PushMe、Chanify、iGot、Qmsg、Pushover、Gotify、ntfy、WxPusher |
| 通用 | Webhook、Email |
| 自定义 | 自定义通知模板 |

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **HTTP 客户端**: Dio
- **本地存储**: SharedPreferences
- **代码编辑器**: 自定义全屏编辑器（支持行号、查找替换、格式化）
- **图表**: CustomPainter 自绘折线图

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── screens/                     # 页面
│   ├── home_screen.dart         # 主界面（9项导航）
│   ├── login_screen.dart        # 登录界面
│   ├── tasks_screen.dart        # 任务管理
│   ├── scripts_screen.dart      # 脚本管理（含全屏编辑器）
│   ├── logs_screen.dart         # 执行日志
│   ├── envs_screen.dart         # 环境变量
│   ├── dependencies_screen.dart # 依赖管理
│   ├── system_screen.dart       # 系统监控
│   ├── security_screen.dart     # 安全设置
│   ├── notifications_screen.dart# 通知渠道
│   ├── config_screen.dart       # 配置管理
│   └── settings_screen.dart     # 设置页面
├── services/                    # 服务层
│   ├── api_service.dart         # API 请求封装
│   └── auth_service.dart        # 认证服务
├── theme/                       # 主题
│   └── miuix_theme.dart         # Miuix 风格主题
└── widgets/                     # 通用组件
    └── miuix_widgets.dart       # Miuix 风格组件
```

## 连接配置

启动 App 后，在登录页面配置面板地址：

- **默认地址**: `http://127.0.0.1:5700`
- **API 路径**: `/api/v1`

确保您的呆呆面板服务已启动，并开启了 API 访问。

## 构建说明

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode（用于构建）

### 本地构建

```bash
# 安装依赖
flutter pub get

# 构建 Android APK
flutter build apk --release

# 构建 iOS IPA（需要 macOS + Xcode）
flutter build ipa --release --no-codesign
```

### GitHub Actions 自动构建

本项目使用 GitHub Actions 自动构建，推送到 `main` 分支会自动触发构建并发布 Release。

构建产物：
- `daidai-flutter-v{x.x.x}-android.apk`
- `daidai-flutter-v{x.x.x}-ios.ipa`

## 版本历史

| 版本 | 主要更新 |
|------|---------|
| v0.0.43 | 恢复仪表盘数据加载逻辑，修复信息未显示问题 |
| v0.0.42 | 修复仪表盘空白、修复滚动条不能手动滑动 |
| v0.0.41 | 修复仪表盘空白、移除重复安全设置、日志详情添加滚动条 |
| v0.0.40 | 页面重构：合并用户管理/个人设置、集成系统监控到仪表盘、移除多余刷新按钮 |
| v0.0.39 | 修复仪表盘导航、日志状态筛选优化、删除配置Tab |
| v0.0.38 | 新增仪表盘、订阅管理、个人设置、用户管理、开放API功能模块 |
| v0.0.37 | 对接 v2.2.17：Python 多版本运行环境、任务级 Python 版本选择、依赖管理 Python 版本切换、备份文件导出导入、深色模式持续优化 |
| v0.0.36 | 修复夜间模式白色背景问题、环境变量和日志页面深色模式适配 |
| v0.0.35 | 依赖管理按钮优化、版本更新 |
| v0.0.38+31 | 面板标题图标自定义、设置页面增强 |
| v0.0.36+29 | 通知渠道扩展18种类型、脚本全屏编辑器、任务重试/依赖/钩子、系统监控趋势图表 |
| v0.0.35+28 | 任务卡片编辑按钮 |
| v0.0.35+27 | Chip组件修复、安装依赖按钮、通知渠道配置 |
| v0.0.35+26 | 登录界面优化、记住密码、自动登录 |
| v0.0.35+25 | 初始 Flutter 版本，基础功能实现 |

## 相关项目

- **呆呆面板后端**: [linzixuanzz/daidai-panel](https://github.com/linzixuanzz/daidai-panel)
- **本项目**: [tall-1997/daidai-flutter](https://github.com/tall-1997/daidai-flutter)

## 许可证

MIT License
