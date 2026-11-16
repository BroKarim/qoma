# Qyube · Constellation Whale

Video promosi 15 detik, 30 fps, 1920 × 956. Satu adegan kontinu dengan screenshot OpenCode sebagai pembuka. Keyframe yang disetujui ada di keyframes-v2, beserta prompt ImageGen aslinya. Komposisi Remotion memakai sprite pulau dan penguin dari video Coworker Flippers serta collectible Constellation Whale dari aset Qyube.

## Prompt yang bisa dipakai ulang

> Create a 15-second Qyube promo from the supplied OpenCode terminal screenshot, the original animated Qyube cove, the common fish sprite, and the Constellation Whale collectible. Use the approved reveal and showcase keyframes as references for staging and light. Keep the original cove silhouette, ice terraces, cave, penguin, orange rod, and tiny bucket. Match the sprite's muted ice blues, teal water, and softly dithered pixel texture. Start with the whole desktop. On frames 60–119, ease the camera from 1× to 3.2× toward the floating island in the bottom right, then lock the camera. Let a common fish swim near the hook as the camera arrives. From 4–7 seconds, build gold ripples and pop a small pixel exclamation mark beside the penguin. From 7–10 seconds, lift the indigo whale through the surface with a pixel splash. From 10–12 seconds, hold the whale in the air with a subtle bob, warm rim light, and sparse gold stars. Keep a clear gap above the pool and keep the penguin and tiny bucket visible to sell the size joke. At 12 seconds, arc the whale into the bucket as it shrinks. Let the last sparkle fade and hold on the cove through 15 seconds. Export a silent H.264 MP4. The tweet goes in the post copy.

## Timeline

| Frames | Action |
|---|---|
| 0–59 | Wide OpenCode desktop |
| 60–119 | Smooth 1× to 3.2× zoom into the cove |
| 120–209 | Common fish, gold ripples, exclamation |
| 210–299 | Whale breaches with pixel droplets |
| 300–359 | Two seconds of floating showcase |
| 360–449 | Whale shrinks into bucket, quiet hold |

The camera and animation are deterministic. The two pictures in keyframes-v2 set the visual direction, while the final comp animates the original video sprite and collectible as layers. No Gallery card or music. The supplied terminal screenshot is used as the desktop plate.

Render with `npm install` and `npm run render`. The composition and workbench manifest live in src. All media it reads are in public.

Tweet: Went fishing for a tiny reward. Pulled up a whole constellation.

To reproduce the exact 15-second delivery file without audio padding, run:

```sh
ffmpeg -i out/constellation-whale.mp4 -map 0:v:0 -c copy -movflags +faststart constellation-whale.mp4
```

The final MP4 decodes fully and contains 450 video frames. The showcase occupies frames 300–359. See out/contact.png for the opening, reveal, showcase, and bucket close.
