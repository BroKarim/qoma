# Active-session prototype generation prompts

Tool: built-in `image_gen.imagegen`. No CLI fallback.

## Initial composition

Use case: ui-mockup.
Create ONE high-fidelity macOS desktop screenshot prototype of qyube during an active focus session, landscape 1536x1024.
Input image 1 is the approved HOME UI STYLE reference only: warm off-white, charcoal, warm grays, gentle rounded edges and subtle elevation. Do NOT reproduce the home window or sidebar.
Input image 2 is the canonical floating PENGUIN reference: reproduce this same watercolor/charcoal penguin, rod, small fixed ice floe and bucket at small desktop-companion size, with no background/frame around the artwork, no water rings. Preserve character identity.
Desktop: entirely plain solid warm light-gray background #E6E3DF, no photo, landscape, wallpaper illustration, gradient, desktop icons, dock or main app window. A thin native-looking menu bar spans the top with small left text "Finder  File  Edit  View  Go  Window  Help". On the upper right show qyube's clickable TIME TEXT ONLY "08:42", with no logo, clock icon, penguin, status dot, pill, chevron or label around it. Farther right separated by generous space, ordinary OS system status and date text "Wed 30 Sep 10:12" may appear.
Floating TIMER: near the upper left, x approx 90 y110. Compact approximately 220px wide by 150px high (about 14% of desktop width), soft off-white rounded rectangle, fine warm-gray border, very subtle shadow matching input1. A tiny discreet gray x close control in its upper-left. In the center show ONLY large charcoal monospaced numerals "08:42". No heading, app name, logo, task title, progress ring/bar, pause/start button, subtitle, labels or bottom toolbar. The number is the focal point.
Floating PENGUIN: near lower-right, visible artwork only approx 130px wide and proportionate height, around x1330 y820, with sufficient safe margin to screen edges. It must feel very small, like a desktop pet. Penguin is quietly fishing atop the reference's same ice floe, bucket at right. All area outside foreground illustration displays the identical desktop background with NO card, rectangular panel, halo, opaque white box, strong water ripples, or ground scene. No text below penguin.
The timer and companion are two widely separated independent floating surfaces. Most of the desktop stays empty. Crisp readable UI, calm clean cozy design. No annotation arrows, explanatory captions, mockup device bezel, collage or headings outside screenshot. Match exact text "08:42" in both timer and menu bar.

## Selected open-state correction

Use case: precise-object-edit. Edit the supplied desktop screenshot prototype with THREE precise corrections.
1. Replace the ENTIRE desktop background below the top menu bar with one perfectly FLAT UNIFORM SOLID COLOR warm light gray #E6E3DF. No dark patches, gradient, photographic blur, texture, vignette, lighting, spotlight, halo, depth-of-field, or scene. This is a solid color desktop. The small floating timer may retain only its tiny subtle local shadow.
2. Reduce the timer panel to exactly approximately 220 px wide by 150 px high within this 1536x1024 screenshot. Keep its current upper left position and white rounded design, discreet close x, and central time "08:42". Remove the diagonal slash across the digit zero: use a standard unslashed rounded 0 and clean numerals.
3. Reduce the entire penguin+ice+bucket illustration to approximately 130 px wide, not 250 px. Place it near the lower right around x1325 y820. Keep same penguin identity, same floe and bucket, fishing pose, no ripple. It must have no white box or halo behind it; outside the art is the same exact flat #E6E3DF as the rest of desktop.
Preserve the top menu bar exactly, particularly qyube time "08:42" alone with no accompanying app logo or icon. Preserve all other UI text. There must be only two floating items: timer and small cutout penguin. No home app. No explanatory labels.

## Closed-state edit

Use case: precise-object-edit. This is the TIMER CLOSED variant of the supplied qyube active-session desktop screenshot. Make exactly ONE change: remove the floating rectangular timer card at upper-left including its x control, number, border and shadow, and fill its former area seamlessly with the surrounding plain warm light-gray desktop color. Preserve EVERYTHING ELSE in the reference: full desktop canvas, entire menu bar, same "08:42" text-only item in top menu bar, same small fishing penguin with same face, floe, rod, bucket, scale and location at bottom right. No app logo or icon beside the menu-bar timer. Do not move, resize or redesign penguin. No new text or controls. This shows an ongoing session where the user closed the floating time panel while the menu-bar timer and fishing companion remain visible.
