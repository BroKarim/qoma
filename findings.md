# Extension System Refactor — Findings

## Current Architecture Issues
1. `FloatingLayoutMode` hardcodes todolist-specific cases
2. `FloatingTimerView` reads `@AppStorage todolistEnabled` directly
3. `WindowManager` reads `todolistEnabled` from UserDefaults
4. `ExtensionsSettingsPane` has hardcoded Todolist card
5. `AnalyticsDashboardView` has hardcoded `if todolistEnabled` block
6. No extension protocol or registry exists

## Bugs Found
1. `TodolistFullView.swift:61` — clear button sets `newItemText = ""` instead of clearing completed
2. `AnalyticsDashboardView.swift:192` — todo analytics shows all-time stats, not filtered by selectedDay
3. `FloatingTimerWindow.swift:48` — `onChange(of: todolistEnabled)` doesn't cancel collapse timer
4. `FloatingTimerWindow.swift:53-57` — 0.5s timer triggers unnecessary size updates

## Dead Code
1. `Constants.swift:135` — `maxVisibleInCollapsed = 10` never used
2. `AnalyticsStore.swift:128` — `reorderTodoItems()` never called
3. `TodoItem.swift:11` — `sessionID` field never populated (keep for future)

## Key Files
- `/Users/kiram/Code/dzenn/Qoma/Utils/Constants.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Floating/FloatingLayoutMode.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Floating/FloatingTimerWindow.swift`
- `/Users/kiram/Code/dzenn/Qoma/Managers/WindowManager.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Main/ExtensionsSettingsPane.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Main/AnalyticsDashboardView.swift`
- `/Users/kiram/Code/dzenn/Qoma/Services/AnalyticsStore.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Floating/TodolistFullView.swift`
- `/Users/kiram/Code/dzenn/Qoma/UI/Floating/TodolistCompactBar.swift`

## Architecture Decision
Use protocol + registry pattern:
- `FeatureExtension` protocol defines extension interface
- `ExtensionManager` singleton manages registration and active state
- `TodolistExtension` concrete implementation
- `FloatingLayoutMode` becomes generic (no extension-specific cases)
- Settings pane iterates registered extensions
- Analytics iterates active extensions' analytics sections
