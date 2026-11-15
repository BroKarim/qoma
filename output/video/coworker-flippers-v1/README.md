# My coworker has flippers

Final: out/coworker-flippers-v1.mp4 — 12 seconds / 360 frames / 30 fps / 1920×1248 / H.264, silent.

Tweet: see tweet.txt. Creative brief, decisions, prompts and frame timeline: DESIGN.md. All source media and generated island frames: public/. Production: prepare.py, src/Film.tsx, src/index.ts, remotion.config.ts. Review: out/qa/.

Rebuild: install dependencies from package.json (or use the existing local node_modules link), run `python3 prepare.py`, then `npm run render`. Run `python3 verify.py` to verify duration, frames and decode. Remotion can add an empty audio track; to remove it without video re-encoding, use FFmpeg `-map 0:v:0 -c:v copy -an -movflags +faststart` to a sibling file, then replace the rendered MP4.

The workbench at http://localhost:5198/?import=project imports the film as desktop / zoom / catch / deposit segments. These are continuous-scene segments with fixed camera/effect timing; detailed effect positions remain in Film.tsx. This is not a seamless wide-to-wide loop. No business app source files changed. Source screenshot contains user-provided editor code and branch filenames; no new desktop or account data captured.

Validation: TypeScript noEmit passed; verify.py confirmed exact12s/360frames and error-free full decode. Workbench parity passed at frames0,90,250 with zero differing pixels. Independent review in out/qa/independent-review.md; review fixes enlarged the caught fish and rebuilt the editor edge. Main scene remains a screenshot with animated companion, not a recording of active typing.

Optional skill follow-ups: credits to the skill author are voluntary: X https://x.com/VincentWei93 ; Douyin https://www.douyin.com/user/MS4wLjABAAAAK1pkjBxilk2Oi_9h_vFyD-lTAu9CTlvhmOtkosDvvxg ; Xiaohongshu https://xhslink.cn/m/At9iP2d5C1V . Showcase https://vincentwei1021.github.io/video-shotcraft/showcase.html and submission https://github.com/Vincentwei1021/video-shotcraft/issues/new?template=showcase.yml . Jianying project export is available as a follow-up.
