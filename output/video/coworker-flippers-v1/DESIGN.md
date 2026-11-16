# My coworker has flippers — v1

Mode: autonomous free creation, continuing the user-approved storyboard. 12 seconds, 360 frames at 30 fps, 1920×1248. Casual Twitter marketing, English tweet, no burned-in titles. Original screenshot Zed desktop is the explicit visual reference; styleframe skipped because composition and product scene are already specified. No template or Gallery variant is claimed: custom single continuous camera push, followed by static character action. The camera motion is a quintic smoothstep with zero velocity and acceleration at its endpoints.

## Product and execution

Qyube is a desktop focus companion with an Arctic fishing scene. The user permits playful nonliteral marketing embellishments. Preserve source penguin, fish movement, snow/ice palette, rounded miniature island and real editor screenshot. No invented app UI. Existing web hero sprites have a different penguin wearing glasses, so do not mix those characters into this shot. Use original source recording, its exterior matte, a common fish and original pixel bird instead.

Original screenshot copied to public/desktop-original.png; desktop.png removes the existing static island so one animated island can replace it. Code screenshot is user-supplied for this explicit video; no credentials, customer records or private communications were observed. No new live desktop capture. Audio: silent, appropriate to the requested casual feed post, with no added BGM, speech or SFX. User can add platform audio later.

| Requirement | Execution |
|---|---|
| Start at macOS desktop with editor | Zed screenshot, full frame 0–59 |
| Zoom into bottom-right penguin | Frames 60–119; smooth 1× to 3.2× camera move |
| Fish, pull and splash | Original penguin fishing/pole motion; added fish approach 120–209, arc 210–278, splash 201–230 |
| Fish enters bucket | Fish arc ends over bucket at frame 279; small landing ring |
| Return to fishing | Original fishing animation holds close view frames 294–359 |
| Decorative life | Light seeded-by-index snow; bird frames 150–200 |

Camera deliberately stays close at end. This is not a seamless loop to the wide desktop opening. No promises about feature behavior; embellished fishing is marketing animation. No BGM means only one video version is needed.

## Files and reproduction

Run `python3 prepare.py`, then `npm run render`. Installed Remotion dependencies are linked from the local skill workbench; install package.json dependencies when moving to another machine. Pillow and FFmpeg are needed for preparation. src/Film.tsx contains the exact deterministic camera and effect timeline. public contains all used media, including source video, original/clean desktop, matte, transparent per-frame island animation, fish and bird. The source blue-sage is not used in this concept because user explicitly changed the opening to their actual desktop screenshot. Earlier snow demo is untouched.

Tweet: My new coworker catches fish while I fix bugs. Honestly, fair division of labor.
