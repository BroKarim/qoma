# Extension System Refactor — Progress Log

## Session 1 — 2026-06-28

### Started
- Created planning files
- Reviewed all 16 extension-related files
- Identified 4 bugs, 3 dead code items
- Designed protocol + registry architecture

### Completed
- Phase 1: Created FeatureExtension protocol, ExtensionManager, TodolistExtension
- Phase 2: Refactored FloatingLayoutMode, FloatingTimerWindow, WindowManager, ExtensionsSettingsPane, AnalyticsDashboardView
- Phase 3: Fixed clear button bug, collapse timer leak, removed unnecessary 0.5s timer
- Phase 4: Removed dead code (maxVisibleInCollapsed, reorderTodoItems), registered TodolistExtension at app launch
- Phase 5: Build succeeded with xcodebuild

### Files Created
- Qoma/Models/FeatureExtension.swift
- Qoma/Managers/ExtensionManager.swift
- Qoma/Extensions/TodolistExtension.swift

### Files Modified
- Qoma/UI/Floating/FloatingLayoutMode.swift
- Qoma/UI/Floating/FloatingTimerWindow.swift
- Qoma/Managers/WindowManager.swift
- Qoma/UI/Main/ExtensionsSettingsPane.swift
- Qoma/UI/Main/AnalyticsDashboardView.swift
- Qoma/UI/Floating/TodolistFullView.swift
- Qoma/Utils/Constants.swift
- Qoma/Services/AnalyticsStore.swift
- Qoma/Managers/AppDelegate.swift

### Bugs Fixed
1. TodolistFullView clear button now actually clears completed items
2. Collapse timer leak fixed in FloatingTimerWindow
3. Removed unnecessary 0.5s timer that caused excessive size updates

### Architecture Changes
- Introduced protocol + registry pattern for extensions
- FloatingLayoutMode is now generic (no hardcoded todolist cases)
- Settings pane iterates registered extensions dynamically
- Analytics section iterates active extension's analytics
- Adding a new extension now only requires:
  1. Create a new file conforming to FeatureExtension
  2. Register it in AppDelegate
  3. Done — settings, floating panel, and analytics pick it up automatically
