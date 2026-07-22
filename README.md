# 呆呆面板 Flutter

呆呆面板 Flutter 是面向 Android 和 iOS 的移动端客户端，用于连接[呆呆面板](https://github.com/linzixuanzz/daidai-panel)服务并在手机端管理定时任务、脚本、环境变量、依赖、安全设置和开放 API。项目基于 [Dumb-Panel-APP](https://github.com/linzixuanzz/Dumb-Panel-APP) 演进而来，采用 Riverpod 状态管理和 GoRouter 路由，界面风格为液态玻璃 (Liquid Glass)。

## 版本

- App 版本：`v0.1.11`
- Dart SDK：`>=3.11.3`
- 适配面板：`v2.3.0+`

## 更新说明

### v0.1.11

- 应用锁：后台返回触发锁定时改用根 ProviderContainer，不再依赖 `rootElement!` 强制解包，异常会输出调试日志。
- 架构：标记 AuthService 中旧式功能 API 包装，避免后续新功能误用旧路径或旧 HTTP 方法。
- Open API：调用日志改为自动分页加载全部记录，避免固定 page size 导致日志截断。

### v0.1.10

- 任务：新增 Cron 模板加载和 Cron 表达式解析预览。
- 任务：新增任务统计和任务日志文件入口。
- Open API：新增获取访问 Token 功能，可通过 App Key/App Secret 获取 24 小时访问令牌。
- 通知：新增主动发送通知入口，可选择渠道并发送自定义标题和正文。
- 系统：新增部署与 Python 运行时状态信息展示。
- 日志流：SSE 支持 Token 过期自动刷新后重连，并按标准 SSE 聚合多行 data 事件。
- 本地通知：权限检查不再触发系统权限申请弹窗，仅在用户点击申请权限时请求授权。
- 环境变量：加载失败时显示明确错误与重试入口。

### v0.1.9

- 任务：新增任务导入/导出入口，支持保存任务导出文件和从 JSON 文件导入任务。
- 环境变量：新增环境变量导入/导出入口，支持导出全部变量和从 JSON 文件导入变量。
- 登录：本地地址、localhost、内网 IP 默认使用 HTTP 协议，公网地址继续默认使用 HTTPS。
- 更新：下载更新包前校验 Release asset 的文件大小和 SHA256 digest，避免复用旧包或损坏包。
- 仪表盘：核心概览数据与可选接口分离加载，面板设置或版本接口异常时仍可展示仪表盘。
- 文档：新增上游功能与问题候选清单，便于按 P0/P1/P2 继续排期。

### v0.1.8

- 更新检测：修复安装同版本修复包后仍反复提示更新的问题，去除同版本 `published_at` 时间回退判定
- 更新检测：保留版本号和 build number 比较，安装当前 Release 后会正确显示已是最新版本
- 发布：重新生成 Android APK 和 iOS IPA 安装包，Release 与仓库说明同步更新

### v0.1.7

- 主题：移除经典风格，全部页面统一使用液态玻璃效果；全局 LiquidGlass theme 配置对齐 iOS26 ultraThickMaterial 材质（light: thickness=32/blur=12, dark: thickness=48/blur=18）
- 导航：主脚手架升级 GlassScaffold + GlassAppBar，底部选项卡升级 premium 品质材质
- 界面：恢复主题设置中的背景图片选择器和模糊强度滑块（0-20 可调）
- 界面：统一全部二级/三级页面卡片背景使用 glassCardColor，移除硬编码 Colors.white/slate900
- 架构：清理 glassMode 状态字段和所有条件分支，减少 200+ 行冗余代码

- 应用锁：开启开关时要求先配置解锁方式，未配置时引导用户前往设置
- 主题：修复经典模式下背景图片被过度模糊遮盖导致不可见问题
- 环境变量：列表卡片布局优化，增大文字和间距，长值自动折行（maxLines 2→8）
- 依赖管理：卡片扩容（padding 10→14），状态/版本/副标题字体增大，间距优化
- 任务列表：状态标签、底部时间、计划摘要字体和间距全面上调
- 用户管理：角色标签、登录/创建时间字体上调，行间距增加
- 日志/订阅/通知：统一调优辅助文字字体大小和行间距

### v0.1.5

- 应用锁：修复生物识别验证失败后界面卡死问题，静默失败时自动切换到密码/图案解锁
- 应用锁：修复仅开启生物识别时可能导致的 lockout 风险
- 界面：修复液态玻璃模式下滑动时底部选项卡变透明问题
- 通知：添加后台通知回调处理和 AppLifecycleObserver，修复后台运行时不推送通知问题
- 安全：添加 WidgetsBindingObserver 监听应用生命周期，切回前台自动触发二次验证

### v0.1.4

- 安全中心：新增登录统计和审计日志 Tab，当前共 6 个 Tab
- SSH 密钥管理：新增 SSH Key 增删改查页面，支持在订阅中关联 SSH Key 进行 Git 认证
- 订阅管理：创建/编辑订阅时新增 SSH Key 下拉选择器
- 面板设置：新增可视化面板外观配置页面（标题、图标、编辑器/日志背景色）
- 脚本调试：新增 `_runCode()` 代码直接执行和 `_clearRun()` 清除运行记录
- 登录诊断：健康检查失败时显示 CORS / NAS 反向代理配置指引，HTTP 状态码异常时给出友好提示
- 移除 `android-native/` 和 `ios-native/` 原生模块

### v0.1.3

- 初始版本，提供 14 个功能模块的完整管理能力

## 软件架构设计

### 分层架构

```
lib/
  core/        -- 基础设施层：认证、网络、存储、主题、路由、系统服务
  features/    -- 功能模块层：每个模块含 views / providers / widgets
  shared/      -- 共享层：数据模型、工具类、公共 UI 组件
```

### 数据流

```
UI (Views) -> Riverpod Providers -> AuthService / DioClient -> REST API
                                                     \-> SSE Client -> Stream
```

- **Views**：用户界面层，Flutter Widget 构建
- **Providers**：Riverpod 状态管理，负责数据获取、缓存与业务逻辑
- **Services**：与后端通信的 API 封装层，包括 REST（Dio）和 SSE 流式推送
- **Storage**：flutter_secure_storage + SharedPreferences 双层持久化

### 路由设计

使用 GoRouter 声明式路由，通过认证守卫控制访问权限。底部导航栏 5 个 Tab：仪表盘、任务、日志、环境变量、更多。

### 主题系统

Material 3 主题 + Liquid Glass 液态玻璃风格，全局对齐 iOS26 ultraThickMaterial 材质（`GlassThemeData` 双模式配置），支持浅色/深色模式切换、自定义背景图片和模糊强度调节。

## 核心功能

### 功能模块总览

| 模块 | 功能概述 |
|------|----------|
| 登录与认证 | 用户名/密码 + TOTP 两步验证，支持极验验证码，本地可信登录会话 7 天有效期 |
| 仪表盘 | 系统概览、CPU/内存/磁盘资源卡片、任务统计、App 版本更新检测 |
| 定时任务 | 任务增删改查、Cron 表达式、启停/置顶/复制/批量操作、导入导出、通知绑定 |
| 执行日志 | 日志列表搜索筛序、批量删除、SSE 实时流式日志、日志清理 |
| 脚本管理 | 脚本文件树浏览/编辑/上传/下载、版本控制、代码直接运行调试 |
| 环境变量 | 变量增删改查、分组/排序/启停/批量操作、导入导出 |
| 依赖管理 | pip/npm 依赖安装/卸载/重装、Python 运行时版本切换、安装日志流式输出 |
| 订阅管理 | Git 仓库/单文件订阅、同步/启停、SSH Key 关联认证 |
| 通知管理 | 钉钉/企微/飞书/Bark 等渠道配置、启停/测试发送、本地推送通知 |
| 安全中心 | 登录日志、在线会话、IP 白名单、审计日志、登录统计、两步验证 |
| 开放 API | API Token 和应用管理、创建/启禁用/重置密钥 |
| 用户管理 | 系统用户增删改查、启禁用 |
| 系统设置 | 并发限制、日志留存、面板更新、数据备份与恢复 |
| 应用锁 | 密码/图案/生物识别，SHA256 迭代哈希存储 |
| 面板设置 | 面板外观配置（标题/图标/编辑器背景/日志背景） |
| SSH 密钥 | SSH Key 增删改查，供订阅 Git 认证使用 |

### 功能模块与依赖库

| 模块 | 引用的依赖库 | 用途 |
|------|-------------|------|
| 路由导航 | `go_router` | 声明式路由、认证守卫、深层链接 |
| 状态管理 | `flutter_riverpod` | 全局状态共享、异步数据加载与缓存 |
| 网络请求 | `dio` + `http` | REST API 调用、Token 自动刷新拦截器 |
| SSE 流式 | `dio` + `http` | 服务端事件流接收，断线自动重连 |
| 安全存储 | `flutter_secure_storage` | Token、用户信息、面板配置的加密存储 |
| 本地存储 | `shared_preferences` | UI 状态、主题偏好、应用锁配置 |
| 图表展示 | `fl_chart` | 仪表盘 CPU/内存趋势图 |
| 生物识别 | `local_auth` | 指纹/面部识别应用锁 |
| 密码哈希 | `crypto` | SHA256 迭代哈希存储应用锁密码 |
| 主题 UI | `liquid_glass_widgets` | 液态玻璃卡片、脚手架、导航栏 |
| 国际化 | `intl` | 日期时间中文格式化 |
| 文件选择 | `file_picker` | 脚本上传、备份文件选择 |
| 设备信息 | `device_info_plus` | 客户端 User-Agent 构建 |
| 应用信息 | `package_info_plus` | 版本号读取、更新检测 |
| 文件路径 | `path_provider` | 应用文档目录访问 |
| WebView | `webview_flutter` | 极验验证码 WebView 弹窗 |
| 本地通知 | `flutter_local_notifications` | 任务执行完成/系统通知推送 |
| 图标生成 | `flutter_launcher_icons` | Android/iOS 应用图标自动生成 |
| 代码分析 | `flutter_lints` | Dart 代码规范检查 |

## 下载安装

| 平台 | 安装包 |
|------|--------|
| Android | [daidai-flutter-v0.1.11-android.apk](https://github.com/tall-1997/daidai-flutter/releases/tag/v0.1.11) |
| iOS | [daidai-flutter-v0.1.11-ios.ipa](https://github.com/tall-1997/daidai-flutter/releases/tag/v0.1.11) |

所有版本见 [GitHub Releases](https://github.com/tall-1997/daidai-flutter/releases)。

## 连接配置

启动 App 后在登录页填写面板地址：

- 默认地址：`http://127.0.0.1:5700`
- 常规接口：`/api`
- 流式接口：`/api/v1`

## 本地构建

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release --no-codesign
```

## 云端构建

推送到 `main` 分支会触发 GitHub Actions 自动构建 APK 和 IPA 并发布到 Release。工作流包括：

- Android 构建 (`android-build.yml`)
- iOS 构建 (`ios-build.yml`)
- 统一构建 (`build.yml`)
- Release 发布 (`release.yml`)

## 开源引用与致谢

本项目基于以下开源项目：

- [Dumb-Panel-APP](https://github.com/linzixuanzz/Dumb-Panel-APP) (Apache 2.0) -- 原始 Flutter 客户端，提供核心功能模块和 UI 设计
- [daidai-panel](https://github.com/linzixuanzz/daidai-panel) (MIT) -- 呆呆面板后端服务，提供 API 接口和数据模型
- [Flutter](https://flutter.dev) (BSD-3-Clause) -- Google 的跨平台 UI 框架
- [Riverpod](https://riverpod.dev) -- Dart/Flutter 响应式状态管理库
- [GoRouter](https://pub.dev/packages/go_router) -- Flutter 声明式路由库
- [Dio](https://pub.dev/packages/dio) -- Dart HTTP 客户端
- [fl_chart](https://pub.dev/packages/fl_chart) -- Flutter 图表库
- [Liquid Glass Widgets](https://pub.dev/packages/liquid_glass_widgets) -- 液态玻璃 UI 组件库
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) -- Flutter 安全存储
- [local_auth](https://pub.dev/packages/local_auth) -- 本地生物认证
- [webview_flutter](https://pub.dev/packages/webview_flutter) -- Flutter WebView

## 许可证

MIT License
