# Requirements Document

## Introduction

本需求覆盖 daidai-flutter 对 daidai-panel v3.0.0 的稳定性修复、功能补齐、残留清理和运行性能优化。交付保持当前 Android/iOS 产品范围，以 Pure Flat 作为默认低成本渲染路径，并保留用户可选的 Liquid Glass 视觉。

## Glossary

- **App**: daidai-flutter 移动客户端。
- **Panel**: daidai-panel v3.0.0 后端。
- **Business terminal event**: SSE 中 event 为 `done` 且 data 表示 finished、installed、failed、not_running、closed 或 timeout 的事件。
- **Reconnect event**: SSE 中 event 为 `done` 且 data 为 `reconnect` 的事件。
- **Complete list**: 后端响应 total 范围内的全部列表项。
- **Raw log**: Panel 磁盘中未经终端语义折叠的日志字节。
- **Bounded log buffer**: 同时限制日志行数和字符总量的内存缓冲区。
- **Foreground page**: App 位于前台且当前路由可见的页面。
- **Request overlap**: 同一数据源的前一项请求仍在执行时开始后一项请求。

## Requirements

### Requirement 1: SSE lifecycle

**User Story:** AS a panel operator, I want real-time streams to stop and reconnect correctly, so that completed operations do not consume resources or duplicate output.

#### Acceptance Criteria

1. WHEN App receives a Business terminal event, App SHALL deliver the event once and close the active stream without scheduling a reconnect.
2. WHEN App receives a Reconnect event, App SHALL schedule one reconnect for the active connection generation.
3. IF an active stream ends before a Business terminal event, App SHALL reconnect when auto reconnect is enabled.
4. WHEN an SSE field uses an optional single space after the colon, App SHALL parse the field value consistently.
5. WHEN an SSE event contains multiple data fields, App SHALL join the values with newline characters and emit one event.

### Requirement 2: Reliable pagination

**User Story:** AS a panel operator, I want paginated lists to preserve continuity during transient failures, so that records remain complete.

#### Acceptance Criteria

1. IF a next-page request fails, App SHALL retain the last successfully loaded page number.
2. WHILE a page request is active, App SHALL issue at most one request for the same list page.
3. WHEN a refresh succeeds, App SHALL replace the current list and reset pagination metadata.
4. WHEN Panel reports additional pages, App SHALL provide a recoverable loading or retry state.

### Requirement 3: Complete auxiliary lists

**User Story:** AS an administrator, I want selectors and management lists to include all available records, so that every configured resource is manageable.

#### Acceptance Criteria

1. WHEN App loads task group candidates, App SHALL derive candidates from the Complete list of tasks within the Panel safe limit.
2. WHEN App loads a paginated auxiliary resource, App SHALL request legal page sizes and continue until total records are collected.
3. IF an auxiliary list request fails, App SHALL show an error state and a retry action.
4. WHILE a resource endpoint returns a direct list, App SHALL preserve compatibility with the direct-list response.

### Requirement 4: Raw log download

**User Story:** AS a panel operator, I want to download original task logs, so that control characters and carriage returns remain available for diagnosis.

#### Acceptance Criteria

1. WHEN a user requests a raw execution log, App SHALL request a resource-bound download ticket from Panel.
2. WHEN a user requests a raw task log file, App SHALL include the selected log locator in the ticket request.
3. WHEN Panel returns a ticket download URL, App SHALL download the file using the returned filename and URL.
4. IF ticket issuance or file download fails, App SHALL preserve the current page and show the Panel error message.

### Requirement 5: Session classification

**User Story:** AS an administrator, I want sessions classified by client, so that active access is easier to identify.

#### Acceptance Criteria

1. WHEN Panel returns client_type_label, App SHALL display the client type label for the session.
2. WHEN Panel returns client_name, App SHALL display the resolved client name.
3. WHEN client classification is absent, App SHALL derive a readable fallback from the user agent.
4. WHEN rendering a session, App SHALL select a stable icon from the client type.

### Requirement 6: Async lifecycle and error recovery

**User Story:** AS a user, I want pages to recover from network failures and navigation races, so that the App remains usable.

#### Acceptance Criteria

1. WHEN a page is disposed during an asynchronous operation, App SHALL discard the completion update.
2. IF platform token loading fails, App SHALL leave the loading state and display a retry action.
3. IF a platform token mutation fails, App SHALL keep the current data and display an error notice.
4. WHEN a mutation succeeds, App SHALL refresh the affected list once.

### Requirement 7: Performance and scrolling

**User Story:** AS a mobile user, I want lists and logs to scroll smoothly while retaining the visual design, so that daily operations feel responsive.

#### Acceptance Criteria

1. WHILE a long list scrolls, App SHALL build visible rows through lazy list builders.
2. WHILE a scrolling card uses Liquid Glass, App SHALL use the shared low-cost scrolling style.
3. WHEN an SSE log line arrives, App SHALL batch UI updates within one display-frame interval.
4. WHEN list filters or unrelated state change, App SHALL limit rebuilds to the affected subtree.
5. WHEN a row leaves the viewport, App SHALL release row-only transient rendering work unless state persistence is required.
6. WHEN measured in Flutter profile mode on a 60 Hz target device, primary task, environment, log, dependency and subscription lists SHALL avoid sustained frame build or raster durations above 16.7 ms during continuous scrolling.

### Requirement 8: Cleanup and compatibility

**User Story:** AS a maintainer, I want obsolete behavior removed and compatible behavior retained, so that future changes have a clear contract.

#### Acceptance Criteria

1. WHEN avatar images use the public Panel avatar route, App SHALL issue a normal image request without constructing an empty Authorization header.
2. App SHALL remove unreferenced local-panel endpoint declarations.
3. App SHALL remove task scroll callbacks that invoke an empty pagination operation.
4. App SHALL preserve task queued-state rendering, refresh-token rotation and standard multi-line SSE behavior.
5. App SHALL retain Pure Flat as the default visual style and Liquid Glass as a user-selectable theme option.

### Requirement 9: Verification

**User Story:** AS a maintainer, I want regression coverage for corrected contracts, so that future releases preserve behavior.

#### Acceptance Criteria

1. App SHALL provide unit tests for SSE field parsing, terminal completion and reconnect decisions.
2. App SHALL provide tests for pagination page commit and rollback behavior.
3. App SHALL provide parsing tests for raw-log ticket and session classification data.
4. WHEN Flutter tooling is available, the delivery pipeline SHALL run formatting, analyze, tests, Android build and iOS build.

### Requirement 10: Bounded runtime memory

**User Story:** AS a mobile user, I want long-running log pages to retain a stable memory footprint, so that extended operations remain responsive.

#### Acceptance Criteria

1. WHEN a real-time log page appends output, App SHALL retain output within a shared maximum line count and maximum character count.
2. WHEN retained output exceeds either limit, App SHALL discard the oldest complete lines until both limits are satisfied.
3. WHEN a page closes, App SHALL release pending log events, timers, stream connections, subscriptions and controllers owned by the page.
4. WHEN App decodes a configurable background image, App SHALL constrain the decoded dimensions to the current display requirements.

### Requirement 11: Polling concurrency and lifecycle

**User Story:** AS a mobile user, I want polling to reflect page visibility and request state, so that network, CPU and battery use remain controlled.

#### Acceptance Criteria

1. WHILE a request for a polling data source is active, App SHALL defer another request for the same data source.
2. WHEN App enters a non-resumed lifecycle state, App SHALL pause page-owned periodic polling.
3. WHEN App resumes and a polling page remains visible, App SHALL perform one refresh and resume the configured interval.
4. WHEN a polling page has no active operation, App SHALL use an idle interval of at least five seconds.
5. WHEN a refresh supersedes a pagination request, App SHALL restore a consistent loading state for the active request generation.

### Requirement 12: Low-cost rendering paths

**User Story:** AS a user on a resource-constrained device, I want visual effects to use predictable GPU resources, so that navigation and scrolling remain smooth.

#### Acceptance Criteria

1. WHILE Pure Flat is selected, App SHALL render page backgrounds, lock overlays and content surfaces without backdrop blur, refraction or real-time scene capture.
2. WHILE Liquid Glass is selected, App SHALL limit page-level scene capture to one capture owner per visible route.
3. WHEN App displays a content surface in Pure Flat, App SHALL use an opaque fill, zero elevation and at most one border.
4. WHEN App navigates between application routes, App SHALL use a fade transition or an immediate transition.
5. WHEN App renders an indeterminate progress animation, App SHALL keep the animation scoped to an active visible operation.

### Requirement 13: Platform process isolation

**User Story:** AS an Android user, I want privileged operations to preserve interface responsiveness, so that system commands cannot block the application frame thread.

#### Acceptance Criteria

1. WHEN Android starts a Root subprocess, App SHALL perform process creation, stream consumption and process waiting outside the platform main thread.
2. WHILE a Root subprocess produces standard output and standard error, App SHALL consume both streams concurrently.
3. IF a Root subprocess exceeds its operation timeout, App SHALL terminate the operation and return a bounded error result.
4. WHEN a Root subprocess completes, App SHALL close process streams and release operation resources.

### Requirement 14: Device performance verification

**User Story:** AS a maintainer, I want repeatable profile evidence on constrained hardware, so that performance changes remain measurable.

#### Acceptance Criteria

1. WHEN a release candidate is profiled on a 60 Hz Android target, App SHALL record UI frame time, raster frame time and peak memory for primary lists and live logs.
2. WHEN App remains in the background for a representative idle period, the verification record SHALL include polling activity and battery-impact observations.
3. WHEN a rendering optimization changes image or glass processing, the verification record SHALL compare visual output in Pure Flat and Liquid Glass.
