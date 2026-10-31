# Qyube account/auth assets — 31 October 2026

Design preparation only. These assets are not connected to application code yet.

## Approved direction update

Use integrated background illustrations with penguin and bucket included, following the prototype. Do not layer the separate welcome penguin onto these backgrounds.

- `signin-fishing-background-v2.png`: sign-in; penguin at lower left with red/cyan 3D glasses hiding its eyes, fishing rod and bucket.
- `account-complete-background-v2.png`: account and completion; relaxed penguin at lower right with closed curved eyes and bucket.
- Both are opaque landscape illustrations with white upper space for live HTML UI. Visually reviewed after generation. Responsive cropping remains to be checked during implementation.
- `auth-antarctic-background.png` and `penguin-welcome.png` are superseded exploration assets, retained for history.

## Inventory

| Asset | Purpose | Source/status |
|---|---|---|
| `prototype-board.png` | Four-screen visual reference; never ship as UI | Built-in imagegen, previous approved direction |
| `auth-antarctic-background.png` | Shared white/pale-blue watercolor background for auth, complete and account | New built-in imagegen output |
| `penguin-welcome.png` | Optional isolated welcome penguin for auth/complete | New built-in imagegen, transparent PNG |
| `../../website/public/hero/penguin-completed.webp` | Existing seated penguin for successful state | Reuse |
| `../../website/public/hero/penguin-fishing.webp` | Existing fishing character when closer landing-page continuity is desired | Reuse |
| `../../website/public/hero/ice-floe.webp` and `bucket-empty.webp` | Optional foreground arrangement | Reuse |
| `../../Qoma/Assets.xcassets/QyubeMenuSignOut.imageset/qyube-menu-sign-out.png` | Illustrated door in native sign-out popover | Reuse; no new door needed |
| `../../Qoma/Assets.xcassets/QyubeMenuSubscription.imageset/qyube-menu-subscription.png` | Existing account/purchase menu illustration | Reuse despite historical asset name |
| Google mark | Google sign-in button | Use official brand asset during implementation; do not AI-generate |
| Check, laptop, desktop, receipt, external-link | Small website UI symbols | Use installed Lucide icons; native symbols where appropriate |

## Implementation handoff

- Keep labels, button shapes, cards and the success check in HTML/SwiftUI. No text is baked into illustration assets.
- Keep raw generated PNGs here; web uses opaque WebP derivatives under `website/public/account/`. Preserve alpha for any future character cutout. Do not replace landing-page artwork.
- Select the integrated v2 background per route. On mobile preserve the character using route-specific positioning and keep the card readable; do not assume a centered cover crop will retain it.
- The native sign-out popover uses existing frame/colors/door artwork. Build its layout natively for keyboard focus, accessibility and accurate text.
- Visual QA: background has white negative space and no text/characters; penguin should have clean alpha edges and no clipped flippers/feet. Browser/native layout QA remains pending.
- Prompt records are in `prompts.md`; built-in imagegen was used, no CLI/API key.
