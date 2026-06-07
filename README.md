# Qoma - Pomodoro & Timer

https://github.com/user-attachments/assets/05fb5ca5-ac03-46b5-92f8-f8cb84091960
<!-- <video src="https://res.cloudinary.com/dctl5pihh/video/upload/v1773037353/qoma-final_ycbwue.mov" controls width="3600"></video> -->

> An open-source floating timer with image support

A minimal timer designed to stay out of your way. Set a duration with the slider
or by typing minutes. You can also show an image in the floating timer, either
as a gentle companion for focus or a simple visual reminder.

## Features

- Floating timer: Qoma can pin a compact always-on-top timer window so countdown progress stays visible without keeping the main window open.
- 3 display modes: the floating window supports `timer only`, `image with timer`, and `image only`, with layout switching handled at runtime.
- Quick presets: menu bar presets let you jump to commonly used focus durations instantly, then start a session without opening full settings.
- Completion sound customization: you can choose the alert sound used when a session finishes and control playback behavior through app settings.
- Floating opacity control: the floating window appearance supports adjustable opacity so it can stay visible but less intrusive over other apps.
- Image positioning: when using image layouts, image offset controls let you fine-tune placement so composition remains readable with timer overlay.

## Install
---
## Direct Download (Recomended)

1. Go to Releases.
2. Download the appropriate DMG file:
   - Apple Silicon (M1/M2/M3/M4/M5): `qoma_*_mac-arm64.dmg`
   - Intel: `qoma_*_mac-intel.dmg`
3. Open the DMG and drag qoma to Applications.
4. First Launch - Choose one method (recommended):
   - Option A: Right-Click Method (Easiest)
     Right-click the app -> Open -> Click Open in the dialog.
   - Option B: Terminal Method (One command, no dialogs) (recommended)
     `xattr -d com.apple.quarantine /Applications/Qoma.app`
5. macOS will show a security warning because the app is not notarized. Use one of these:
   - Recommended (one command):
     `xattr -d com.apple.quarantine /Applications/Qoma.app`
   - Or via UI:
     **System Settings > Privacy & Security > Open Anyway**.

> Note: This is an ad-hoc signed indie app. macOS shows a warning for apps not notarized through Apple's $99/year developer program. The app is completely safe and open source.

## Homebrew

```sh
brew tap qoma-app/pomodoro
brew install --cask qoma-pomodoro
```

Update:

```sh
brew update
brew upgrade --cask qoma-pomodoro
```


## License

This project is licensed under the BSD 3-Clause [License](LICENSE) - see the LICENSE file for details.


