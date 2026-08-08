# 上游功能与 Bug 审计

本文档对比当前 Flutter 客户端、上游 `Dumb-Panel-APP` 和后端 `daidai-panel`，记录已确认的功能差异、API 适配状态与缺陷。

## 分析基线

| 项目 | 版本 | Commit |
| --- | --- | --- |
| 当前客户端 `tall-1997/daidai-flutter` | `0.1.56+56` | `92355e70de69af43fb9499b3bbd98bb7bbf9ba65` |
| 上游客户端 `linzixuanzz/Dumb-Panel-APP` | `1.2.6+19` | `03b9ef655d8b80393c7faa865099d63cd35562a4` |
| 后端 `linzixuanzz/daidai-panel` | `v3.0.0` | `28636ea58da134ad6e1e440cb937726336700cdc` |

审计日期：2026-08-08。

当前环境没有 Flutter/Dart SDK，结论来自源码和接口契约静态复核，尚未执行 `flutter analyze`、`flutter test` 或真机联调。

## 后端 v3.0.0 适配状态

### 已适配

- API 前缀：后端同时注册 `/api` 和 `/api/v1`，当前客户端继续使用多数 `/api` 路径可兼容。
- 任务全量查询：任务列表使用 `all=1`，后端安全上限为 5000 条，见 `lib/features/tasks/providers/task_provider.dart:67-94`。
- 任务排队状态：客户端将状态 `0.5` 映射为“排队中”，见 `lib/shared/models/task.dart:70-79`。
- Refresh Token：客户端从 `Authorization` 头发送 Refresh Token，并支持轮换及并发刷新协调。
- SSE 基础能力：通用客户端支持 Bearer Token、401 刷新、CRLF、多行 `data` 聚合和断线重连。
- 会话数据：后端为会话和登录日志返回 `client_type`、`client_type_label`、`client_name`，当前页面可继续展示现有字段。
- 分页响应：客户端公共解析器支持后端的 `data`、`total`、`page`、`page_size` 包装。

### 本轮已补齐功能

1. 原始日志票据下载
   - 后端新增 `GET /logs/:id/raw-ticket` 和 `GET /tasks/:id/log-files/:filename/raw-ticket`，签发两分钟有效的资源绑定票据。
   - 客户端已增加票据模型、接口端点和流式文件下载服务。
   - 执行日志和任务日志文件页面已提供原始字节下载入口，文件保存到应用文档目录下的 `downloads`。

2. 会话客户端分类展示
   - 后端已返回 `client_type_label` 和 `client_name`。
   - 会话页已显示客户端类型标签、客户端名称和稳定类型图标。

3. 后端列表契约复核
   - 后端分页默认每页 20 条，`page_size` 有效范围为 1 至 100。
   - 任务和环境变量支持 `all=1|true|yes`，最多返回 5000 条。
   - 用户、SSH 密钥、通知渠道、平台令牌和 Open API 应用接口直接返回完整列表，客户端保持单次请求。

## 本轮已修复 Bug

### P1：SSE 终态后持续重连

位置：

- `lib/core/network/sse_client.dart:138-159`
- `lib/core/network/sse_client.dart:181-198`
- 受影响调用包括任务日志、执行日志、依赖日志和订阅拉取流。

触发条件：服务端发送 `event: done`，数据为 `finished`、`installed`、`failed`、`not_running`、`closed` 或 `timeout`，随后正常关闭响应流，调用方启用 `autoReconnect`。

原因：客户端只对 `done/reconnect` 显式安排重连，流正常结束时又对所有自动重连连接无条件调用 `scheduleReconnect()`，缺少“已收到业务终态”标记。

影响：完成后的连接每秒重建，持续消耗网络、电量和后端连接；重新连接可能再次返回完整历史日志并造成重复内容。

修复状态：`SseClient` 已记录业务终态、立即关闭连接并阻止 EOF 重连；异常 EOF、网络错误和 `done/reconnect` 保持自动重连。调用页面统一使用协议判断函数处理带可选空白的数据。

### P1：安全日志加载失败后跳页

位置：

- 登录日志：`lib/features/security/views/security_page.dart:151-181`
- 审计日志：`lib/features/security/views/security_page.dart:1375-1400`

触发条件：加载下一页前执行 `_page++`，该页请求发生超时、断网或服务端错误，用户继续滚动。

影响：下一次请求直接访问后续页，失败页的数据在当前会话中缺失。

修复状态：登录日志和审计日志已改为请求成功后提交目标页码，并增加重复请求门禁。

### P1：Open API 调用日志加载失败后跳页

位置：

- `lib/features/openapi/views/open_api_page.dart:1055-1076`
- `lib/features/openapi/views/open_api_page.dart:1112-1158`

原因与安全日志一致：`_loadMore()` 先递增页码，异常路径没有回滚。

影响：调用日志产生数据断层，底部加载指示器可能持续触发更后面的页。

修复状态：调用日志已改为请求成功后提交目标页码，并增加重复请求门禁。

### P2：任务分组候选只扫描前 20 条任务

位置：`lib/features/tasks/views/task_form_page.dart:243-260`。

客户端发送 `page_size=200`。后端 v3.0.0 接受的最大值为 100，越界后回退为 20，客户端又只读取第一页。因此仅出现在后续任务中的分组不会成为表单候选，用户仍可手动输入。

修复状态：任务分组候选已使用 `all=1` 获取完整任务集合。

### P2：订阅日志页面存在异步销毁竞态

位置：`lib/features/subscriptions/views/subscription_list_page.dart:1353-1364`。

页面初始化先等待日志背景色，再调用 `_load()`。用户在等待期间离开页面时，后续 `_load()` 会在首次 `setState()` 前缺少 `mounted` 检查，可能触发 `setState() called after dispose()`。

修复状态：背景色异步读取和后续加载均已增加生命周期门禁。

### P2：平台令牌加载失败永久显示加载态

位置：`lib/features/security/views/platform_tokens_page.dart:22-33`。

首次 `Future.wait` 任一请求失败时，方法直接抛出，`_loading` 保持 `true`，页面没有错误状态或重试入口。新增、编辑、启停和删除操作也缺少统一错误反馈。

修复状态：平台令牌页面已增加 generation 隔离、错误状态、重试入口、操作忙状态和统一错误反馈。

### P2：SSE 字段格式兼容范围偏窄

位置：`lib/core/network/sse_client.dart:170-179`。

解析器只识别 `event: ` 和 `data: `，标准 SSE 允许 `event:value`、`data:value` 以及字段值前可选的单个空格。当前后端固定输出带空格格式，因此这属于协议健壮性缺口。

Android Runtime 页面在 `lib/features/deps/views/android_runtime_page.dart:61-71` 维护另一套更简化的行解析器，也仅识别 `data: `，并通过日志文本符号判断失败。

修复状态：通用客户端和 Android Runtime 均使用标准字段解析，兼容字段值前可选空格、CRLF 和多行 `data`；Android Runtime 根据 `done` 结果判断安装状态。

## 已排除候选

- 头像认证：后端 `GET /auth/avatar/:filename` 是公开静态资源路由，个人资料页使用普通 `NetworkImage` 可以加载。`more_page.dart` 构造空 Authorization 头属于可清理实现，当前不会阻断公开头像。
- 通用 SSE Token 刷新：当前 `SseClient` 已复用 `TokenRefreshCoordinator`，401 后最多刷新一次并重连。
- SSE 多行数据：当前通用解析器已按空行聚合多行 `data`。
- 任务列表分页：当前任务列表使用 `all=1`，空 `loadMore()` 属于失效交互残留，5000 条安全上限内不会产生分页缺失。
- 任务排队状态：当前客户端已支持状态 `0.5`。

## 与上游 App v1.2.6 的功能差异

### 当前客户端新增

- 任务视图管理、过滤规则和排序规则。
- 任务导入导出。
- 服务端 Cron 模板和表达式解析预览。
- 本地任务完成通知、通知权限设置和点击深链。
- 个人头像、用户名和密码管理。
- 环境变量批量改名、置顶和多格式导出工具。
- Android/Magisk Runtime 管理。
- pip/npm 已安装清单、依赖导出和顺序批量重装。
- 平台令牌管理与 SSH 私钥管理。
- 配置脚本编辑器和系统健康诊断。
- 可持久化主题、背景图片和模糊强度。
- Android 差分更新、安装包 MD5/SHA-256 校验及完整包回退。
- Refresh Token 轮换、并发刷新协调和服务器切换隔离。
- 未保存脚本直接调试运行。

### 上游客户端独有

- 任务卡左滑快捷操作：启停、置顶、复制、编辑和删除。
- Flutter Web/PWA 平台外壳。

当前项目已明确移除任务卡侧滑操作，并聚焦 Android/iOS 移动客户端，这两项属于产品范围差异。

## 已清理残留

- 已移除 `lib/core/network/api_endpoints.dart` 中无调用点的 `/api/local/*` 端点。
- 已移除任务列表的空 `loadMore()` 调用和 Provider 空实现。
- 已移除公开头像请求构造的空 `Authorization` 头。

## 剩余验证

1. 在具备 Flutter SDK 的环境执行 `dart format .`、`flutter analyze` 和 `flutter test`。
2. 执行 Android 与 iOS 构建，确认原始日志票据接口和移动端文件保存行为。
3. 使用 Flutter profile 与 DevTools 验证浅色/深色、快速滚动、分组展开和窄屏场景的帧耗时。
