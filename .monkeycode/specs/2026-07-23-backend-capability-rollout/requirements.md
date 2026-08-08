# Requirements Document

## Introduction

面向 daidai-panel 旧版至 v3.0.1+ 的移动端能力适配。App 与面板保持独立升级，基础功能优先加载，增强功能依据当前面板的实际端点能力自动显示或隐藏。

## Glossary

- **核心功能**：认证、仪表盘核心数据、任务列表和依赖列表等页面主要功能。
- **增强功能**：任务视图、面板设置、独立版本信息和多 Python runtime 等可选能力。
- **能力档案**：以规范化面板 URL 为作用域保存的端点支持状态和探测时间。
- **明确不支持**：端点返回 404、405 或后端明确声明功能不可用。
- **临时失败**：超时、断网、连接失败或 5xx 响应。

## Requirements

### Requirement 1

1. WHEN 用户进入个人资料页, App SHALL 提供头像、用户名和密码管理。
2. WHEN 用户名或密码修改成功, App SHALL 清理认证会话并返回登录页。
3. WHEN 头像变更成功, App SHALL 刷新当前用户状态。

### Requirement 2

1. WHEN 用户进入系统诊断页, App SHALL 展示数据库、内存、调度器和网络检查结果。
2. WHEN 用户触发立即检查, App SHALL 调用 POST 健康检查并展示最新时间。

### Requirement 3

1. WHEN 用户管理任务视图, App SHALL 支持视图 CRUD、隐藏和排序。
2. WHEN 用户选择任务视图, App SHALL 将 filters 和 sort_rules 应用于任务查询。

### Requirement 4

1. WHEN 非管理员访问管理员路由, App SHALL 返回更多页。
2. WHEN 页面加载失败, App SHALL 区分 Loading、Empty 和 Error 并提供重试。

### Requirement 5

1. App SHALL 提供平台和平台令牌 CRUD、启停和筛选。
2. App SHALL 提供 config.sh 多行编辑、复制、刷新和保存。
3. App SHALL 提供 Android runtime 状态、安装日志和卸载。
4. App SHALL 提供 pip/npm 实际清单、依赖导出和批量重装。
5. App SHALL 提供环境变量批量改名、置顶和多格式文件导出。

### Requirement 6

**User Story:** AS 面板用户, I want App 根据当前面板能力调整功能入口, so that App 与面板可以独立升降级。

#### Acceptance Criteria

1. WHEN App 连接面板, App SHALL 以实际端点响应确定增强功能的可用状态。
2. WHEN 增强端点返回 404、405 或明确不支持响应, App SHALL 在当前面板作用域内隐藏对应功能。
3. IF 增强端点发生临时失败, App SHALL 保留对应功能的未知状态和后续重试能力。
4. WHEN 能力档案到达有效期, App SHALL 重新探测对应能力。
5. WHEN 用户切换面板, App SHALL 使用目标面板 URL 对应的能力档案。

### Requirement 7

**User Story:** AS 面板用户, I want 页面先展示核心内容, so that 增强接口延迟或缺失不会阻塞基本操作。

#### Acceptance Criteria

1. WHEN 仪表盘开始加载, App SHALL 并行请求系统信息和仪表盘核心数据。
2. WHEN 仪表盘核心数据返回, App SHALL 在面板设置和版本信息请求完成前展示核心数据。
3. WHEN 任务页开始加载, App SHALL 在任务视图探测完成前请求并展示任务列表。
4. WHEN 依赖页开始加载, App SHALL 在 Python runtime 探测完成前请求并展示当前依赖类型。
5. WHILE 页面已有可用数据, App SHALL 在刷新期间继续展示现有数据。

### Requirement 8

**User Story:** AS 面板用户, I want 启动和认证请求减少平台存储等待, so that 页面导航和并发请求具有稳定响应时间。

#### Acceptance Criteria

1. WHEN App 恢复认证会话, App SHALL 将 Access Token 加载到当前进程的认证快照。
2. WHEN App 发送认证请求, App SHALL 从认证快照读取 Access Token。
3. WHEN 登录、Token 刷新、退出或面板切换更新认证会话, App SHALL 同步更新认证快照和安全存储。
4. WHEN 多个请求同时收到 401, App SHALL 共享一次 Token 刷新并并发重放积压请求。
5. WHEN 登录或可信会话恢复成功, App SHALL 由目标页面负责核心数据首次加载。

### Requirement 9

**User Story:** AS 多面板用户, I want 每个面板的数据和能力独立管理, so that 切换面板时不会看到其他面板的状态。

#### Acceptance Criteria

1. WHEN App 缓存页面数据或能力状态, App SHALL 使用规范化面板 URL 隔离缓存。
2. WHEN 用户切换面板, App SHALL 清理当前页面中的上一面板瞬时状态。
3. WHEN 面板升级或降级改变端点响应, App SHALL 在能力档案重新探测后更新功能入口。
