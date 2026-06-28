# Qoma

A menu-bar Pomodoro focus app with session tracking, analytics, and an extensible floating timer panel.

## Language

**Extension**:
A module that modifies the floating timer panel's behavior (Feature) or appearance (Design). Toggled on/off from Settings → Extensions.
_Avoid_: Plugin, add-on, module

**Feature Extension**:
An Extension that adds interactive functionality to the floating timer panel (e.g., Todolist). At most one Feature Extension can be active at a time.
_Avoid_: Widget, tool

**Design Extension**:
An Extension that changes the visual shape or style of the floating timer panel (e.g., custom shape, animation). At most one Design Extension can be active at a time. Can coexist with a Feature Extension.

**Floating Timer Panel**:
An NSPanel that stays above all windows, showing the countdown. Its content and size change dynamically based on which Extensions are active.
_Avoid_: Popup, overlay, HUD

**Basic Mode**:
The default state of the Floating Timer Panel when no Extensions are active. Shows only the countdown timer.

**Collapsed State**:
A compact view of the Floating Timer Panel when a Feature Extension is active. Shows the timer (smaller), two action buttons (add, show completed), and one summary item. Enters automatically after a short period of user inactivity.

**Expanded State**:
A full view of the Floating Timer Panel when a Feature Extension is active. Shows all extension content (e.g., full todolist). Activated by tapping on the Collapsed State.

**Todo Item**:
A single task in the Todolist Extension. Carries a title, completion flag, creation date, and optional notes. Supports drag-and-drop reordering.

**Todolist Extension**:
The first Feature Extension. Adds a checklist to the Floating Timer Panel with add, complete, reorder, and inline notes.

**Extension Toggle**:
A UserDefaults-backed (`@AppStorage`) Boolean in Settings → Extensions that enables or disables an Extension.
