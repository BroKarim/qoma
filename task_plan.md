# Extension System Refactor — Task Plan

## Goal
Refactor the hardcoded Todolist extension system into a generic protocol + registry pattern, fix bugs, and remove dead code.

## Phases

### Phase 1: Foundation (New Files)
- [ ] Create `Qoma/Models/FeatureExtension.swift` — protocol definition
- [ ] Create `Qoma/Managers/ExtensionManager.swift` — registry, active extension tracking
- [ ] Create `Qoma/Extensions/TodolistExtension.swift` — concrete conformance

### Phase 2: Refactor Existing Files
- [ ] Refactor `FloatingLayoutMode.swift` — generic cases
- [ ] Refactor `FloatingTimerWindow.swift` — use ExtensionManager
- [ ] Refactor `WindowManager.swift` — use ExtensionManager
- [ ] Refactor `ExtensionsSettingsPane.swift` — iterate registered extensions
- [ ] Refactor `AnalyticsDashboardView.swift` — iterate extension analytics

### Phase 3: Bug Fixes
- [ ] Fix clear button in `TodolistFullView.swift:61`
- [ ] Fix analytics date filtering in `AnalyticsDashboardView.swift:192`
- [ ] Fix collapse timer leak in `FloatingTimerWindow.swift:48`
- [ ] Remove unnecessary 0.5s timer in `FloatingTimerWindow.swift:53-57`

### Phase 4: Cleanup
- [ ] Remove `maxVisibleInCollapsed` from Constants
- [ ] Remove `reorderTodoItems` from AnalyticsStore
- [ ] Register TodolistExtension at app launch

### Phase 5: Verify
- [ ] Build with xcodebuild
- [ ] Confirm no compile errors

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| (none yet) | — | — |

## Decisions
- Remove dead code (`reorderTodoItems`, `maxVisibleInCollapsed`) per user request
- Use protocol + registry pattern for extensibility
- Keep existing file structure where possible
