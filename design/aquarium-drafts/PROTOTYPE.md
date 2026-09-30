# Standalone macOS Aquarium prototype

Implemented on branch `aquarium`, September 2026. Open **Settings → Aquarium** in the Qoma app, or the standalone `AquariumView` Xcode preview. Requires macOS 14+; older systems show an availability message. Existing app deployment target and other pages remain unchanged.

## Included

- Ice Pool-inspired white content area and rounded blue tiled pool.
- Four original procedural vector creatures: koi, clownfish, blue tang and spotted ray.
- Continuous body deformation, separate fin/tail motion, bounded swimming paths.
- Swaying seaweed, rocks, starfish, discarded bottle, top-down yellow submarine with propeller and bubbles.
- Metal water shader with moving caustic light and gently warped floor tiles.
- Pause/resume and water-effects controls; Reduce Motion freezes the scene; Low Power Mode lowers the refresh target to 15 FPS and disables water effects.
- Animation time belongs to the scene subtree. It freezes on disappearance/inactive scene and resumes without a wall-clock jump.

All content is local dummy content. No timer, Catalog, analytics, persistence, network, purchase or collection integration. Fish follow smooth deterministic courses in this prototype; obstacle avoidance, flocking and collectible selection are not implemented. These are editable vector illustrations, not the detailed painted assets from the concept image.

## Files

- `Qoma/UI/Aquarium/AquariumView.swift`: screen, controls and animation clock.
- `Qoma/UI/Aquarium/AquariumArtwork.swift`: vector art and motion.
- `Qoma/UI/Aquarium/AquariumWater.metal`: water shader.
- `Qoma/UI/SettingsView.swift`: navigation entry.
- `qoma.xcodeproj/project.pbxproj`: Metal 2.4 language setting for stitchable shaders.

## Verification

- Debug arm64 macOS build passed using `xcodebuild build -project qoma.xcodeproj -scheme Qoma -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO`.
- Installed the official Xcode Metal Toolchain component required by the shader compiler.
- A temporary Swift harness checked 216,000 position samples across three simulated hours: finite coordinates, safe pool bounds and continuous displacement all passed.
- Rendered Canvas frames at 0 and 8 seconds and visually inspected them.
- Rendered the actual `AquariumView` at 640×580 with the compiled Metal library. Snapshot: `04-prototype-implemented.png`.
- `git diff --check` passed.
- Live app interaction checks remain manual: Computer Use permission/connection timeout prevented clicking controls in the running app. No measured FPS or battery benchmark is claimed.
- Existing project warnings about concurrency, old source formatting and Info.plist in Copy Bundle Resources were outside this prototype's scope.

## Manual review

Open Aquarium, observe swimming and water movement, toggle water, pause/resume, switch to another sidebar page and return. Check Reduce Motion and Low Power Mode behavior on device. The aim of this pass is to judge the feel of motion and the composition before refining asset detail.
