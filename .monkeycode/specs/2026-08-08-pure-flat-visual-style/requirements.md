# Requirements Document

## Introduction

本需求为 daidai-flutter 增加可切换的视觉风格。App 默认使用低 GPU 占用的 Pure Flat 纯扁平极简风格，并保留 Liquid Glass 液态玻璃风格供用户主动选择。两种风格使用独立渲染路径，避免 Pure Flat 页面创建液态玻璃捕获、折射、模糊或多层半透明渲染对象。

## Glossary

- **App**: daidai-flutter 移动客户端。
- **Visual Style**: 控制组件与页面渲染实现的外观设置。
- **Pure Flat**: 使用不透明色块、单层边框和 Material 控件的低成本视觉风格。
- **Liquid Glass**: 使用 `liquid_glass_easy` 捕获、折射和玻璃控件的视觉风格。
- **Color Mode**: 浅色、深色或跟随系统的配色设置。
- **Fresh Install**: 尚未保存 Visual Style 的 App 安装状态。

## Requirements

### Requirement 1: Default visual style

**User Story:** AS a mobile user, I want the App to use a low-cost visual style by default, so that common pages consume fewer GPU resources.

#### Acceptance Criteria

1. WHILE App has no persisted Visual Style, App SHALL select Pure Flat.
2. WHEN App starts, App SHALL load the persisted Visual Style before rendering style-dependent shared surfaces.
3. WHEN a user selects a Visual Style, App SHALL persist the selection for subsequent launches.
4. WHEN a user upgrades from a version without Visual Style persistence, App SHALL select Pure Flat.

### Requirement 2: Independent style and color controls

**User Story:** AS a user, I want to choose visual effects independently from light and dark colors, so that I can combine the preferred appearance and brightness.

#### Acceptance Criteria

1. App SHALL expose Pure Flat and Liquid Glass choices in Theme Settings.
2. App SHALL retain light, dark and system Color Mode choices.
3. WHEN a user changes Visual Style, App SHALL apply the selected style without changing Color Mode.
4. WHEN a user changes Color Mode, App SHALL apply the selected colors without changing Visual Style.

### Requirement 3: Pure Flat rendering isolation

**User Story:** AS a performance-sensitive user, I want Pure Flat to avoid liquid-glass rendering work, so that GPU cost remains predictable.

#### Acceptance Criteria

1. WHILE Pure Flat is active, App SHALL render the main shell with Material layout and an opaque bottom navigation surface.
2. WHILE Pure Flat is active, App SHALL render shared cards, surfaces, inputs, toggles, buttons, chips and dialog actions with Material widgets.
3. WHILE Pure Flat is active, App SHALL render secondary-page backgrounds without `LiquidGlassView`.
4. WHILE Pure Flat is active, App SHALL render theme controls without `LiquidGlassSlider` or `LiquidGlassToggle`.
5. WHILE Pure Flat is active, App SHALL omit backdrop blur, refraction, real-time capture and layered translucent backgrounds from the style-dependent shared rendering path.
6. WHEN Pure Flat renders a surface, App SHALL use one opaque fill and at most one border layer.
7. WHILE Pure Flat is active and a background image is configured, App SHALL display the original image without blur behind opaque content surfaces.

### Requirement 4: Liquid Glass rendering isolation

**User Story:** AS a user who prefers visual effects, I want Liquid Glass to retain the existing appearance, so that the optional style remains available.

#### Acceptance Criteria

1. WHILE Liquid Glass is active, App SHALL use the existing `LiquidGlassScaffold`, `LiquidGlassView`, `LiquidGlassBottomNavBar` and shared liquid-glass controls.
2. WHILE Liquid Glass is active, App SHALL retain the configured background image and blur controls.
3. WHEN a user switches from Pure Flat to Liquid Glass, App SHALL rebuild style-dependent shared surfaces using the Liquid Glass path.
4. WHEN a user switches from Liquid Glass to Pure Flat, App SHALL release Liquid Glass widgets through normal Flutter subtree disposal.

### Requirement 5: Pure Flat visual consistency

**User Story:** AS a user, I want the low-cost style to remain clear and consistent, so that reduced effects preserve usability.

#### Acceptance Criteria

1. WHILE Pure Flat is active, App SHALL provide distinct page, surface, border, control and selected-state colors in light and dark Color Modes.
2. WHILE Pure Flat is active, App SHALL preserve primary, warning and danger semantic colors.
3. WHILE Pure Flat is active, App SHALL preserve existing spacing, touch targets, responsive layouts and accessibility labels.
4. WHILE Pure Flat is active, App SHALL use opaque modal, menu, dialog, card, input and navigation surfaces.

### Requirement 6: Verification

**User Story:** AS a maintainer, I want automated and manual checks for both styles, so that future changes preserve rendering isolation.

#### Acceptance Criteria

1. App SHALL provide tests for the default Visual Style and persisted Visual Style loading.
2. App SHALL provide widget tests showing that Pure Flat shared controls omit liquid-glass widget types.
3. App SHALL provide widget tests showing that Liquid Glass shared controls use the liquid-glass rendering path.
4. App SHALL provide tests showing that Color Mode and Visual Style changes remain independent.
5. WHEN Flutter tooling is available, the delivery pipeline SHALL run formatting, analyze, tests, Android build and iOS build.
