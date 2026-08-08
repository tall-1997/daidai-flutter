# v3 Stability, Capability and Performance

Feature Name: v3-stability-performance
Updated: 2026-08-08

## Description

本设计一次性交付已确认缺陷修复、daidai-panel v3.0.0 缺口、残留清理，以及面向低端 Android 设备的渲染、内存、生命周期和并发性能优化。Pure Flat 作为默认低成本路径，Liquid Glass 保留为受限捕获范围的可选路径。

## Architecture

```mermaid
graph TD
    A["Feature pages"] --> B["DioClient"]
    A --> C["Paginated loader"]
    A --> D["SseClient"]
    B --> E["daidai-panel v3.0.0"]
    C --> B
    D --> E
    A --> F["Lazy scrolling widgets"]
    F --> G["Low-cost Liquid Glass style"]
    A --> H["File download service"]
    H --> B
    A --> I["Bounded log buffer"]
    A --> J["Lifecycle-aware poller"]
    A --> K["Visual style render path"]
    K --> L["Pure Flat opaque surfaces"]
    K --> M["Bounded Liquid Glass capture"]
    A --> N["Android platform channel"]
    N --> O["Background Root process executor"]
```

`SseClient` 维护单连接 generation、终态标记和重连决策。分页页面采用“请求目标页，成功后提交页码”的事务式更新。原始日志下载先请求票据，再复用文件下载服务保存后端返回的文件。实时日志统一写入有界缓冲区。周期请求由页面可见性、App 生命周期和单请求互斥共同控制。渲染层按视觉风格分流，Android Root 子进程由后台执行器负责。

## Components and Interfaces

### SseClient

- 将行字段解析提取为可测试的纯函数。
- 接受 `field:value` 与 `field: value`。
- 在单连接作用域记录业务终态。
- 业务终态关闭连接；reconnect 事件和异常 EOF进入重连。
- 日志密集调用方通过短周期缓冲批量提交 UI。

### Pagination

- 下一页计算使用 `targetPage = currentPage + 1`。
- 网络请求成功后更新 `currentPage`。
- 失败后保留当前页，暴露错误或重试操作。
- 辅助全量列表使用合法 `page_size=100`；任务和环境变量优先使用后端 `all=1`。

### Raw Log Download

- 新增执行日志与任务日志文件 ticket endpoint。
- ticket DTO 读取 `url`、`filename`、`expires_at`。
- 下载 URL 支持后端返回绝对 URL和相对 URL。
- 文件保存复用现有 file picker/path provider 约定，采用流式写入。

### Session Presentation

- 会话行读取 `client_type`、`client_type_label`、`client_name`。
- client type 映射稳定图标，未知类型使用设备图标。
- user agent 保留为次级诊断信息。

### Platform Tokens

- 页面状态增加错误文本和 mutation busy 状态。
- load 使用 `try/catch/finally` 与 mounted 检查。
- CRUD 操作统一捕获后端错误并显示 `AppGlassNotice`。

### Scrolling Performance

- 长列表保留 `ListView.builder`、`SliverList` 或 `ReorderableListView.builder`。
- 长列表中的 `AppCard` 统一设置 `stableForScrolling: true`。
- 高频日志流批量 setState，避免每行触发整页重建。
- Riverpod 页面使用 `.select` 订阅局部状态。
- 固定尺寸或可预测行高的位置设置 `itemExtent` 或 `prototypeItem`。
- Pure Flat 使用不透明表面、零 elevation 和单层边框。
- Liquid Glass 页面限制为单个捕获所有者，滚动内容使用共享低成本样式。

### Bounded Log Buffer

- 共享工具维护日志行列表和当前字符总量。
- 追加前规范化换行，追加后从头部裁剪完整行。
- 默认上限兼顾诊断可用性与低端设备内存，调用方可按业务收窄上限。
- 批量追加返回实际保留的行数，页面继续使用 builder 惰性渲染。

### Lifecycle-aware Polling

- 页面通过 `WidgetsBindingObserver` 感知 resumed 与非 resumed 状态。
- 每个轮询数据源维护单独的 in-flight 标记。
- App 恢复时立即刷新一次，随后重建周期计时器。
- 页面销毁时取消计时器并使请求 generation 失效。

### Rendering Cost Control

- 应用锁根据视觉风格选择不透明遮罩或受限玻璃效果。
- 背景图片根据逻辑尺寸和设备像素比设置缓存解码宽高。
- 路由统一使用 fade 或即时页面构造。
- 页面级 Liquid Glass 捕获链只保留一个实时捕获入口。

### Android Root Process Executor

- MethodChannel handler 快速切换到 IO dispatcher。
- stdout 与 stderr 使用两个并发读取任务，避免任一管道填满阻塞进程。
- 进程等待具有明确超时，完成和异常路径统一关闭流并销毁进程。
- 结果切回主线程交付 Flutter engine。

## Data Models

```dart
class RawLogTicket {
  final String url;
  final String filename;
  final DateTime? expiresAt;
}
```

分页状态遵循以下字段：

```dart
class PageState<T> {
  final List<T> items;
  final int page;
  final int total;
  final bool loading;
  final String? error;
}
```

## Correctness Properties

- 每个 SSE generation 最多存在一个活动连接和一个重连计时器。
- 每个业务终态事件对调用方最多投递一次。
- 页码始终表示最后一个成功合并到列表的页面。
- 下载票据仅用于后端返回的绑定资源 URL。
- 异步回调仅在 mounted 且请求 generation 有效时更新页面。
- 性能优化保持业务数据、操作入口和视觉层级不变。
- 日志缓冲在任意追加后同时满足行数和字符数上限。
- 每个轮询数据源最多存在一个活动请求。
- 非 resumed 生命周期中不存在页面周期轮询计时器。
- Android 平台主线程不执行 Root 进程等待或流读取。

## Error Handling

- SSE 认证失败沿用 Refresh Token single-flight；刷新失败清理会话。
- 分页错误保留现有数据并提供重试。
- ticket 和下载错误使用 `extractErrorMessage`，保存失败展示目标文件错误。
- 平台令牌与辅助列表使用 `AppAsyncState` 或同等 Loading、Empty、Error 状态。
- 生命周期竞争通过 mounted 和 request generation 双重隔离。
- 日志裁剪保留最新完整行，超长单行保留末尾诊断内容。
- 轮询异常结束后在 finally 中释放 in-flight 状态。
- Root 命令超时返回稳定错误结构，并释放子进程资源。

## Test Strategy

- SSE 解析器：可选空格、CRLF、多行 data、注释、业务终态、reconnect、异常 EOF。
- 分页：首次加载、下一页成功、下一页失败、重复触发、刷新覆盖。
- DTO：raw ticket 包装与直接响应、会话字段缺失回退。
- Widget：平台令牌加载失败与重试、会话分类展示。
- 有界缓冲：空输入、批量追加、行数裁剪、字符裁剪和超长单行。
- 轮询：请求互斥、刷新覆盖分页、进入后台、恢复前台和页面销毁。
- Widget：Pure Flat 应用锁无 backdrop blur、Liquid Glass 捕获层级和路由转场类型。
- Android：Root 执行成功、双流大量输出、超时和异常退出的本地测试。
- Profile：使用 Flutter DevTools 检查任务、环境变量、日志、依赖、订阅连续滚动；记录 build/raster frame 时间和 rebuild 统计。
- Device：在低端 Android 真机记录前后台网络活动、峰值内存和背景图片解码占用。
- 工具链门禁：`dart format`、`flutter analyze`、`flutter test`、Android 构建和 iOS 构建。

## References

- `.monkeycode/docs/UPSTREAM_FEATURE_AND_BUG_CANDIDATES.md`
- `lib/core/network/sse_client.dart`
- `lib/features/security/views/security_page.dart`
- `lib/features/openapi/views/open_api_page.dart`
- `lib/features/tasks/views/task_form_page.dart`
- `lib/shared/widgets/app_card.dart`
