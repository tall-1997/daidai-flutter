# 上游功能与 Bug 审计

本文档对比当前 Flutter 客户端、`linzixuanzz/Dumb-Panel-APP` 和 `linzixuanzz/daidai-panel` 的全部正式 Release，记录移动客户端相关的缺陷、接口契约和功能差距。

## 分析基线

| 项目 | 审计范围 | 当前基线 |
| --- | --- | --- |
| `tall-1997/daidai-flutter` | 当前仓库 | `0.1.57+57`，`cda35a8fcaf2e02f6fdc0f1785a396e628c6519b` |
| `linzixuanzz/Dumb-Panel-APP` | 18 个正式 Release | `v1.0.2` 至 `v1.3.0` |
| `linzixuanzz/daidai-panel` | 73 个正式 Release | `v0.1.1` 至 `v3.0.1` |

审计日期：2026-08-08。Release 统计排除了 draft 和 prerelease。早期仅包含 Full Changelog 的 Release 已结合 tag、compare commit 和后端源码核对。

本轮已完成静态审计和客户端修复实现。动态网络、Token 轮换、跨版本降级和真机文件流程仍需联调验证。

## 结论摘要

| 分级 | 数量 | 重点 |
| --- | ---: | --- |
| P0 | 3 | 任务导入协议、环境变量导入协议、邮件配置值类型 |
| P1 | 10 | 通知配置无损保存、备份完整性、任务和日志终止状态、任务新增字段、系统配置覆盖范围、订阅 Token 鉴权 |
| P2 | 11 | 错误空态、未知枚举、动态 schema、凭据展示、长耗时、仪表盘统计、认证重放风险 |
| P3 | 1 | 环境变量导入预检和模式体验 |

证据等级定义：A 表示当前客户端与固定后端源码直接证明；B 表示客户端源码和框架确定行为证明；C 表示前向兼容或运行环境相关风险。

## 实现状态

- P0、P1、P2 和 P3 列出的客户端修复均已实现，并为导入解析、通知配置、订阅鉴权、任务与日志契约、系统配置 schema 增加回归测试。
- 通知凭据与订阅 Token 编辑采用空值保留策略；未知通知类型和未知配置键保持可编辑、可回写。
- 系统设置、任务列表和日志列表已提供加载错误与重试入口。
- 当前环境缺少 Flutter/Dart SDK，格式化、静态分析、自动测试和双平台构建保留为待执行门禁。

## P0 数据与接口缺陷

### P0-1：任务导入使用错误的请求格式

- 状态：确认存在。
- 位置：`lib/features/tasks/views/task_list_page.dart:164-192`。
- 触发条件：用户选择任务导出文件并执行导入。
- 当前行为：以 `multipart/form-data` 上传 `file`。
- 后端契约：`POST /tasks/import` 使用 `ShouldBindJSON`，请求体要求 `{"tasks": [...]}`。
- 影响：后端返回请求参数错误，任务导入不可用。客户端导出保存的是 API 包装响应，导入前还需提取任务数组。
- 证据等级：A。
- 修复：读取并解析 JSON，兼容导出响应包装，提交 `tasks` 数组，并增加导出后立即导入的契约测试。

### P0-2：环境变量导入使用错误的请求格式

- 状态：确认存在。
- 位置：`lib/features/envs/views/env_list_page.dart:415-443`。
- 触发条件：用户选择环境变量文件并执行导入。
- 当前行为：以 `multipart/form-data` 上传 `file`。
- 后端契约：`POST /envs/import` 使用 JSON，字段为 `envs` 和 `mode`，请求上限 1 MiB。
- 影响：后端无法绑定 `envs`，导入不可用。
- 证据等级：A。
- 修复：客户端解析文件后提交 `{"envs": [...], "mode": "merge"}`，支持 `merge/replace`。

### P0-3：邮件 `smtp_ssl` 保存为 bool

- 状态：确认存在。
- 位置：`lib/features/notifications/views/notification_list_page.dart:727,825-845,882-911`。
- 触发条件：创建邮件渠道，或编辑后保存已有邮件渠道。
- 当前行为：写入 `{"smtp_ssl": true}` 或 `false`。
- 后端契约：通知配置解码为 `map[string]string`；`smtp_ssl` 具有自动、开启、关闭三态。
- 影响：整份配置可能解码失败，测试发送和正式通知均可能返回 `invalid config`。
- 证据等级：A。
- 修复：所有通知配置值统一序列化为字符串；邮件 SSL 使用 `auto/on/off` 三态控件，并兼容历史别名。

## P1 行为与兼容缺陷

### P1-1：已知通知渠道保存时删除未知字段

- 状态：确认存在。
- 位置：`lib/features/notifications/views/notification_list_page.dart:723-760,882-905`。
- 触发条件：服务端配置含新字段、扩展字段或客户端字段表未覆盖的键，用户在 App 中保存渠道。
- 影响：未知键被静默删除。邮件 `from` 已构成直接案例，可能改变发件人、认证参数或扩展行为。
- 证据等级：A。
- 修复：从 `existingConfig` 副本开始保存，只覆盖用户编辑过的键。

### P1-2：通知类型辅助请求失败会隐藏已有渠道

- 状态：确认存在。
- 位置：`lib/features/notifications/views/notification_list_page.dart:87-124,228-258`。
- 触发条件：旧面板缺少 `/api/notifications/types`，或该辅助端点失败、无权限。
- 影响：通知主列表即使请求成功，页面仍显示“暂无通知渠道”。
- 证据等级：A。
- 修复：主列表与类型列表独立加载；类型请求失败时使用 fallback 类型。

### P1-3：手动备份遗漏 `task_views`

- 状态：确认存在。
- 位置：`lib/features/system/views/backup_page.dart:56-133,228-236,375-393,862-905`。
- 触发条件：用户通过 App 创建备份。
- 影响：任务视图名称、过滤规则、排序和隐藏状态不会进入备份，恢复后丢失。
- 证据等级：A。
- 修复：在备份选择模型、JSON、标签、开关和默认值中完整加入 `task_views`。

### P1-4：`last_run_status=2` 被显示为失败或忽略

- 状态：确认存在。
- 位置：`lib/features/tasks/views/task_list_page.dart:2163-2176,2239-2278,3170-3183`。
- 触发条件：任务被停止并以中止状态结束。
- 后端契约：`0=成功`、`1=失败`、`2=已终止`。
- 影响：详情错误显示“失败”，列表缺少终止结果。
- 证据等级：A。
- 修复：集中定义运行结果枚举并统一展示。

### P1-5：日志 `status=3` 缺少映射和筛选

- 状态：确认存在。
- 位置：`lib/shared/models/task_log.dart:5,26-40`、`lib/features/logs/views/log_list_page.dart:562-602,700-704`。
- 触发条件：日志以中止状态结束。
- 后端契约：`3=已终止`。
- 影响：列表显示“未知”，无法筛选，颜色与运行中接近。
- 证据等级：A。
- 修复：模型、详情、筛选项和颜色统一支持状态 3。

### P1-6：任务缺少 `success_exit_codes`

- 状态：功能缺失。
- 位置：`lib/shared/models/task.dart:4-34,119-186`、`lib/features/tasks/views/task_form_page.dart:455-473`。
- 触发条件：任务需要把 `0` 之外的退出码视为成功。
- 影响：App 无法查看或配置；新建任务使用服务端默认 `0`。普通字段级编辑会保留服务端已有值。
- 证据等级：A。
- 修复：加入模型、表单、校验、序列化和导入导出测试。

### P1-7：任务缺少 `notify_on_abort`

- 状态：功能缺失。
- 位置：`lib/features/tasks/views/task_form_page.dart:167-171,455-473,884-919`。
- 触发条件：用户需要配置任务终止通知。
- 影响：App 无法查看或修改；新建任务采用服务端默认 `false`。
- 证据等级：A。
- 修复：在通知设置中增加独立终止开关并完整透传。

### P1-8：系统设置仅覆盖固定配置子集

- 状态：部分实现。
- 位置：`lib/features/system/views/system_settings_page.dart:31-40,104-141,526-543,850-1028`。
- 触发条件：面板注册新配置，或用户管理固定表单之外的配置。
- 影响：资源告警、通知、订阅覆盖、标题、时区、定时备份、最大会话数、CAPTCHA、可信代理和默认 Python 等配置只能从 Web 管理。
- 证据等级：A。
- 修复：消费 `/api/configs` 的 `value_type/group/default_value/description/options/registered` 动态生成控件。

### P1-9：系统配置保存可能覆盖陈旧值并形成部分提交

- 状态：确认存在。
- 位置：`lib/features/system/views/system_settings_page.dart:526-545`。
- 触发条件：页面加载后其他客户端修改配置，或批量保存中某个后续键校验失败。
- 影响：未编辑字段可能覆盖新值；失败响应前的部分键可能已经生效。
- 证据等级：A。
- 修复：只提交加载值与当前值的差异；失败后重新加载服务端最终状态。

### P1-10：订阅缺少 HTTP Token 鉴权字段

- 状态：功能缺失。
- 位置：`lib/shared/models/subscription.dart:1-124`、`lib/features/subscriptions/views/subscription_list_page.dart:454-728,780-1061`。
- 触发条件：私有 Git 仓库使用用户名和 Personal Access Token，而非 SSH Key。
- 后端契约：支持 `auth_type=token`、`auth_username`、`auth_token`、`has_auth_token`；更新时空 Token 保留旧值。
- 影响：App 只能选择 SSH 密钥，无法创建或完整编辑 Token 鉴权订阅，也无法展示已保存凭据状态。
- 证据等级：A。
- 修复：模型和表单加入鉴权类型、用户名、Token 与“已配置”状态，保持空 Token 不覆盖旧值。

## P2 稳健性与体验差距

| 项目 | 状态与影响 | 位置 | 证据 |
| --- | --- | --- | --- |
| 任务列表首屏错误显示为空数据 | 请求失败显示“暂无任务”，缺少错误和重试 | `lib/features/tasks/providers/task_provider.dart:11-98`、`task_list_page.dart:1186-1247` | A |
| 日志列表吞掉请求异常 | 请求失败显示“暂无日志”，缺少错误和重试 | `lib/features/logs/views/log_list_page.dart:20-101,608-643` | A |
| 未知任务状态显示为已禁用 | 未来状态值会造成错误操作判断 | `lib/shared/models/task.dart:70-80` | C |
| 未知任务类型显示为常规定时 | 列表和详情误报，编辑下拉还可能断言 | `task_list_page.dart:2218-2226,3097-3105`、`task_form_page.dart:623-634` | B/C |
| 未知依赖状态显示为已安装 | 新增状态值会被误报为成功安装 | `lib/shared/models/dependency.dart:34-48` | C |
| 日志耗时缺少小时格式 | 7325 秒显示为 `122m5s` | `lib/shared/models/task_log.dart:43-50` | A |
| 通知字段 schema 静态化 | `NotificationTypeOption` 只保留 type/name，新字段仍依赖硬编码 Map | `notification_list_page.dart:21-31,493-721` | C |
| 通知凭据明文显示 | 多类 token、secret 和 key 可被肩窥或录屏捕获 | `notification_list_page.dart:525-700` | A |
| 系统配置字段语义偏差 | “日志背景色”实际写入 `editor_background_color`；旧面板日志大小 fallback 小 1000 倍 | `system_settings_page.dart:115-128,877-954` | A |
| 仪表盘缺少今日终止统计 | 仅展示成功和失败，无法观察终止趋势 | `lib/features/dashboard/widgets/task_stats_card.dart:11-79` | A |
| Token 刷新重放存在自等待风险 | 重放请求再次 401 时，同一拦截器可能把请求加入自身等待队列 | `lib/core/auth/auth_interceptor.dart:42-69` | B |

认证重放建议为每个请求增加一次性 retry 标记；重放再次 401 时立即清理会话并拒绝全部队列。业务 `403` 继续作为授权或 scope 错误展示，保持与登录失效分离。

## P3 导入体验

### P3-1：环境变量导入缺少模式与本地预检

- 状态：功能缺失。
- 位置：`lib/features/envs/views/env_list_page.dart:415-469`。
- 影响：修复 JSON 协议后，用户仍无法选择 `merge/replace`；客户端也未预检 1 MiB 上限、变量名、条目数量及文件内重复的 `(name, remarks)`。
- 修复：提供模式选择；`replace` 增加数据替换确认；提交前校验文件和重复身份。

## 已正确处理

- App/Web 会话隔离：所有 Dio 和 raw Dio 请求携带 `X-Client-Type: app`，见 `lib/core/network/app_user_agent.dart:18-27`。
- 会话展示：页面消费 `client_type`、`client_type_label` 和 `client_name`。
- Unicode 用户名：客户端与后端均使用 Unicode 字母、数字、下划线的 1 至 32 字符规则，见 `lib/features/profile/views/profile_page.dart:87-96`。
- HTTP 成功范围：全局 Dio 和 raw Dio 仅接受 `2xx`，登录 `4xx` 也会显式转为异常。
- 普通业务 `401`：支持 Refresh Token 轮换、并发刷新协调和原请求重放。
- SSE：每次连接重新读取 Access Token；握手 `401` 刷新后重连一次；支持 CRLF、多行 data、业务终态和异常 EOF 重连。
- 任务字段：`python_version`、多 Cron 和 `timeout=0` 已正确解析、保留和保存。
- 服务端任务复制：客户端直接调用复制接口，服务端负责透传完整字段。
- 环境变量：按记录 ID 编辑，保留同名多值语义；列表、模型和编辑支持多分组。
- 环境变量 `by-name`：该接口用于脚本 upsert，当前 App 的按 ID CRUD 无需接入。
- 订阅分页：使用合法上限 `page_size=100` 并继续分页。
- 任务全量查询：使用 `all=1`，后端安全上限为 5000 条。
- 任务排队状态：已支持状态 `0.5`。
- Cron 模板：已通过 `/api/tasks/cron/templates` 动态加载。
- 原始日志：已实现票据下载和系统文件保存流程。
- 任务视图：CRUD 已实现，当前缺口集中在备份选择。
- 头像：后端头像路由公开，普通 `NetworkImage` 可加载。

## 产品范围差异

- 当前客户端额外提供任务视图、本地通知、环境变量工具、Android Runtime、依赖重装、平台令牌、SSH 私钥、配置脚本、健康诊断、主题背景和 Android 差分更新。
- 上游 App 提供任务卡左滑快捷操作和 Flutter Web/PWA 外壳。
- 当前项目已明确采用无任务卡侧滑操作的 Android/iOS 产品范围，上述两项不列为缺陷。

## 动态验证清单

1. 在 `daidai-panel v3.0.1` 联调任务和环境变量 JSON 导入，覆盖合法文件、包装响应、非法字段、1 MiB 上限、merge 和 replace。
2. 创建并编辑邮件渠道，验证 `smtp_ssl` 三态、历史别名、未知字段保留和测试发送。
3. 使用短时 Access Token 验证并发 `401`、刷新成功、重放再次 `401` 和 Refresh Token 失效。
4. 验证 SSE 长时间断网、Token 轮换、业务 `403` 和终态关闭。
5. 使用超过 100 条订阅验证完整分页，并联调 SSH 和 Token 两类私有仓库。
6. 使用旧面板验证 `/notifications/types` 和动态 `/configs` 缺失时的降级行为。
7. 在具备 Flutter SDK 的环境执行 `dart format .`、`flutter analyze`、`flutter test`，并构建 Android 与 iOS。
8. 修改卡片渲染后验证浅色、深色、快速滚动、分组展开、窄屏和侧滑环境变量卡。

## 修复顺序

1. 修复任务导入、环境变量导入和邮件配置类型三个 P0。
2. 保证通知配置无损保存，并补齐 SMTP 三态与类型端点降级。
3. 补齐 `task_views` 备份、任务终止结果和日志终止状态。
4. 补齐 `success_exit_codes`、`notify_on_abort` 和订阅 Token 鉴权。
5. 改造动态系统配置与差异保存。
6. 增加任务和日志错误态、未知枚举、小时耗时及认证重放回归测试。
