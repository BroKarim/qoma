# Task Plan: Dzenn Product Specification and Release-1 Roadmap

## Goal

Produce a durable, implementation-ready product specification and a four-month Release-1 roadmap for the Dzenn focus-and-collection app, preserving every agreed product decision.

## Current Phase

Complete — Documentation delivered

## Phases

### Phase 1: Consolidate Approved Product Decisions

- [x] Capture the product direction, platform boundaries, and business model.
- [x] Capture all decisions from the design interview.
- [x] Record constraints, edge cases, and deferred scope.
- **Status:** complete

### Phase 2: Verify Existing Product Baseline and External Constraints

- [x] Review the existing macOS project and its current documentation.
- [x] Inspect the fishing-animation reference and aquarium reference.
- [x] Verify Apple platform constraints, Deep Focus APIs, purchase model, and sync approach.
- **Status:** complete

### Phase 3: Write Product and Technical Specification

- [x] Define terminology, session rules, reward rules, collection rules, analytics, and platform behavior.
- [x] Define the Deep Focus, data, sync, animation, accessibility, privacy, and monetization contracts.
- [x] Review the specification against every approved decision and existing-code constraints.
- **Status:** complete

### Phase 4: Build the Four-Month Release-1 Roadmap

- [x] Divide Release 1 into achievable weekly milestones.
- [x] Include validation gates and the Deep Focus entitlement contingency.
- [x] Review sequencing and dependencies against the current codebase.
- **Status:** complete

### Phase 5: Deliver and Verify Documentation

- [x] Confirm files are present, internally consistent, and readable.
- [x] Update progress and close this documentation task.
- **Status:** complete

## Key Questions

1. What product rules must remain invariant across macOS and iOS? Answered in `PRODUCT_SPEC.md`.
2. What should be deferred so Release 1 remains achievable in four months? Answered in `ROADMAP.md`.
3. How can iOS Deep Focus ship safely despite Apple entitlement risk? Release without it if approval is late.
4. How can Universal Purchase remain true while the legacy Mac build used direct DMG/Sparkle? Make Mac App Store the primary Release-1 channel; validate retained Mac tracking under sandbox/review constraints in Week 1.

## Decisions Made

| Decision | Rationale |
|---|---|
| Dzenn is a focus session app, not a conventional Pomodoro/break app | The user selects an intentional timer; the core reward loop is fishing and collection. |
| Release 1 targets macOS 14+ and iOS 17+ | Enables the selected SwiftUI, SwiftData, Metal, and Screen Time foundations. |
| Rewards bank after five active minutes | Prevents very short farming while not punishing a legitimate interrupted focus session. |
| Catalog counts species; Aquarium renders one instance per discovered species/item | Keeps the collection meaningful while keeping the aquarium performant. |
| Use an append-only completed-session sync model | Avoids live-timer conflicts and duplicate collection totals across devices. |
| Release without Deep Focus if Apple entitlement approval is late | One entitlement must not block the whole product. |

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Web-result formatter assumed an MCP content array | 1 | Used direct JSON output; no research data was lost. |
| Markdown validation found metadata trailing whitespace | 1 | Removed the hard-break spaces; normal paragraph lines preserve the same content. |
| Completion-log patch used an outdated line context | 1 | Read the current files and used a narrower patch. |

## Notes

- This plan governs documentation work only; it does not authorize implementation changes yet.
- Existing unrelated working-tree changes remain untouched.
