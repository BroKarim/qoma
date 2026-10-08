# Native distraction render checks

These PNGs are captured from the real AppKit/SpriteKit renderers, using private fixtures and a deterministic clock. No AI-generated replacement illustration was introduced during this polish pass; the existing watercolor components and hop art are reused.

- `contact-sheet.png`: fishing plus the ice reaction, flippers-up, intermediate bow, and full bow. Small dark-background samples make alpha seams easier to spot.
- `ice-06.png`, `ice-10.png`, `ice-18.png`, `ice-24.png`: accumulation at 1, 11, 31, and51 seconds.
- `lights-bright.png`, `lights-mid.png`, `lights-dark.png`, `lights-bright-again.png`: transparent, 17.5%, 35%, and transparent veil.

Recreate from the Debug executable using `--companion-snapshots <directory>` and `--distraction-snapshots <directory>`. Neither command starts a focus session or modifies collections. The overlay check also checks WindowServer ordering against its fixture when windows are on-screen.

These snapshots establish the rendered poses and opacity, not every external app's fullscreen/Spaces behavior or subjective sound quality. Production uses the user's supplied MP3 files through data assets, verified as decodable by the integration tests.
