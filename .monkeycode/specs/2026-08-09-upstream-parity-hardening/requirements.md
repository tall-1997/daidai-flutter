# Requirements Document

## Introduction

本需求修复 daidai-flutter 对齐 Dumb-Panel-APP v1.0.2 至 v1.3.0 后确认的数据完整性、会话隔离、流式连接、跨面板状态、错误恢复、文件下载和发布资产问题。

## Glossary

- **App**: daidai-flutter 移动客户端。
- **Panel**: daidai-panel 后端实例。
- **Session Epoch**: 标识当前认证会话的进程内单调递增编号。
- **Panel Scope**: 规范化后的面板 URL。
- **Multi-Cron Task**: 包含一个或多个 `cron_expressions` 的任务。
- **Release Asset Set**: 正式 Release 中的 APK、IPA、Android 更新清单和有效差分包。

## Requirements

### Requirement 1: Multi-Cron integrity

**User Story:** AS a panel operator, I want every Cron expression preserved during editing, so that saving a task does not change its schedule unexpectedly.

#### Acceptance Criteria

1. WHEN App opens a Multi-Cron Task, App SHALL display every effective Cron expression in source order.
2. WHEN App saves a Multi-Cron Task, App SHALL submit the complete expression list and the first expression as the compatibility value.
3. WHEN App parses Cron templates, App SHALL preserve template groups and compatible field aliases.
4. WHEN App displays Cron preview, App SHALL identify the Panel execution timezone or state that Panel settings determine the timezone.

### Requirement 2: Session isolation

**User Story:** AS a user, I want asynchronous work bound to the active login session, so that old requests cannot affect a new session.

#### Acceptance Criteria

1. WHEN a login, logout or Panel switch creates a new session, App SHALL advance Session Epoch.
2. WHEN a REST response belongs to an expired Session Epoch, App SHALL discard the response.
3. WHEN a Token refresh belongs to an expired Session Epoch, App SHALL discard the refresh result and preserve the active session.
4. WHEN an SSE callback belongs to an expired Session Epoch, App SHALL discard the callback and stop reconnection.

### Requirement 3: Panel-scoped state

**User Story:** AS a multi-panel user, I want each Panel to retain independent data and interface state, so that switching Panels does not expose stale content.

#### Acceptance Criteria

1. WHEN App switches Panel Scope, App SHALL reset every Panel data Provider before navigation completes.
2. WHEN a Provider response belongs to an old Panel Scope, App SHALL discard the response.
3. WHEN App stores task interface state, App SHALL use a Panel-scoped key.
4. WHEN App restores task interface state, App SHALL restore search, status, group, view and scroll state for the active Panel Scope.

### Requirement 4: Reliable SSE continuation

**User Story:** AS a panel operator, I want live logs to resume without duplicates, so that reconnects preserve accurate output.

#### Acceptance Criteria

1. WHEN an SSE event provides an ID, App SHALL store the ID and send `Last-Event-ID` during reconnection.
2. WHEN an SSE stream provides a retry value, App SHALL use the value as the reconnect base delay.
3. WHEN connection failures continue, App SHALL apply bounded exponential backoff.
4. WHEN an explicit event ID repeats, App SHALL deliver the event once.
5. WHEN App enters a background lifecycle state, App SHALL pause page-owned streams and resume active streams after foreground restoration.

### Requirement 5: Compatible data editing

**User Story:** AS a user, I want server-defined values preserved during editing, so that newer Panel values remain intact.

#### Acceptance Criteria

1. WHEN a task-view endpoint returns a supported wrapped list, App SHALL parse the complete list.
2. WHEN an enum current value is absent from known options, App SHALL display and preserve the current value.
3. WHEN an existing list refresh fails, App SHALL retain content and display a recoverable inline error.

### Requirement 6: Raw log handling

**User Story:** AS a panel operator, I want to save or share original logs reliably, so that diagnostic files remain accessible.

#### Acceptance Criteria

1. IF a raw-log ticket is expired, App SHALL request one replacement ticket before download.
2. IF a ticket download returns an expiry response, App SHALL retry once with a replacement ticket.
3. WHEN sharing a raw log, App SHALL use temporary storage and clean temporary artifacts after sharing.
4. WHEN saving a raw log, App SHALL preserve a unique safe filename in application documents.

### Requirement 7: Release integrity

**User Story:** AS a maintainer, I want every formal Release to contain verified install and update assets, so that upgrades remain reliable.

#### Acceptance Criteria

1. WHEN a version tag starts a formal Release, the pipeline SHALL require complete Android signing credentials.
2. WHEN the pipeline builds an APK, the pipeline SHALL verify the APK signature before upload.
3. WHEN a previous compatible APK exists, the pipeline SHALL generate and reconstruct-verify a beneficial patch.
4. WHEN the pipeline publishes a Release, the Release Asset Set SHALL contain a validated Android update manifest.
5. WHEN main or pull-request CI runs, the pipeline SHALL build and test without publishing formal assets.

### Requirement 8: Navigation and notifications

**User Story:** AS an operator, I want discoverable authorized features and meaningful local notifications, so that available actions are accessible.

#### Acceptance Criteria

1. WHILE an operator is authenticated, App SHALL show every operator-authorized automation entry.
2. WHILE a viewer is authenticated, App SHALL hide operator and administrator entries.
3. WHEN App detects a new version and system notifications are enabled, App SHALL publish one version-specific local notification.
4. WHEN a user opens an update notification, App SHALL navigate to the update entry.

### Requirement 9: Verification

**User Story:** AS a maintainer, I want regression coverage for corrected contracts, so that future changes preserve behavior.

#### Acceptance Criteria

1. App SHALL provide tests for Multi-Cron round trips, Session Epoch, wrapped task views, enum preservation and capability TTL.
2. App SHALL provide tests for SSE ID, retry, terminal state and reconnect decisions.
3. App SHALL provide tests for raw-log ticket expiry and Android update asset selection.
4. WHEN Flutter tooling is available, the pipeline SHALL run formatting, analysis and tests before platform builds.
