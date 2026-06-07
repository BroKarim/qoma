# Qoma - Pomodoro & Timer

https://github.com/user-attachments/assets/05fb5ca5-ac03-46b5-92f8-f8cb84091960
<!-- <video src="https://res.cloudinary.com/dctl5pihh/video/upload/v1773037353/qoma-final_ycbwue.mov" controls width="3600"></video> -->

> An open-source floating timer with image support

A minimal timer designed to stay out of your way. Set a duration with the slider
or by typing minutes. You can also show an image in the floating timer, either
as a gentle companion for focus or a simple visual reminder.

## Features

- ⏱️ **Floating Timer** — Pin a compact always-on-top timer window so countdown progress stays visible without keeping the main window open.
- 🎯 **Focus Sessions** — Start, pause, resume, and stop focus sessions with break mode support.
- 🎨 **Theme & Opacity** — Adjustable floating window opacity and theme selection.
- 📊 **App & Website Tracking** — Monitor time spent in applications and websites (Safari, Chrome, Edge, Arc, Brave, Vivaldi, Opera, Firefox experimental).
- 📈 **Visual Analytics** — Charts showing daily/weekly activity patterns, heatmap, top apps, and top websites breakdown.

## TODO

- [ ] Analytics / website tracking not working yet
- [ ] Add more pomodoro styles
- [ ] Visual effect after 1 session done
- [ ] More analytics features
- [ ] Migrate from JSON to SwiftData

## Install

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

## Permission Setup

Qoma requires several macOS permissions to function properly.

### Required Permissions

**Automation Permission:** To track browser activity
- System Settings → Privacy & Security → Automation
- Enable Qoma for your browsers (Safari, Chrome, Edge, Arc, Brave, Vivaldi, Opera, Firefox)

**System Events Permission:** For browser integration
- System Settings → Privacy & Security → Automation
- Enable Qoma for System Events

**Accessibility Permission:** For Firefox browser integration
- System Settings → Privacy & Security → Accessibility
- Enable Qoma

**Firefox Additional Setup:** Firefox does not expose tab URLs through its scripting interface, so Qoma reads the address bar via the macOS Accessibility API. This requires a one-time Firefox configuration change. Firefox website tracking is experimental and may stop working if Firefox changes its accessibility hierarchy, if the toolbar is customized, or while the browser UI is in a transient state:
- Open Firefox and navigate to `about:config`
- Accept the risk warning if prompted
- Search for `accessibility.force_disabled`
- Set the value to `-1`

**Notifications (Optional):** For session completion and update notifications
- System Settings → Notifications → Qoma
- Enable notifications as desired

### In-App Permission Prompts

The app provides helpful banners and direct links to the appropriate system preference panes when permissions are needed.


## Building from Source

```sh
git clone https://github.com/BroKarim/qoma.git
cd qoma
open qoma.xcodeproj
```

Then select your scheme (Qoma) and run from Xcode (Cmd+R).


## License

This project is licensed under the BSD 3-Clause [License](LICENSE) - see the LICENSE file for details.

