# Qoma v1.1.0

## Download

| Platform | Architecture | Download |
|---|---|---|
| macOS | Universal (Apple Silicon + Intel) | `qoma-1.1.0-mac-universal.dmg` |

## Installation

1. Download `qoma-1.1.0-mac-universal.dmg` (works on any Mac).
2. Open the DMG and drag **Qoma** to **Applications**.
3. Remove quarantine flag (ad-hoc signed, not notarized):

```bash
xattr -d com.apple.quarantine /Applications/Qoma.app
```

> macOS shows a warning for apps not notarized through Apple's $99/year developer program. The app is safe and open source.

---

# Release Checklist

Alur release manual Qoma. Sehari-hari app dibuka dari Xcode (Debug), tapi untuk distribusi build Release.

**Kondisi saat ini:**
- Belum ada akun Apple Developer (tidak bisa notarize, Sparkle signing di-skip).
- Repo app: `BroKarim/qoma`
- Repo Homebrew tap: `BroKarim/homebrew-qoma`

## Step 1 - Update MARKETING_VERSION

Di `qoma.xcodeproj/project.pbxproj`, update `MARKETING_VERSION` ke versi baru (Debug + Release config, Qoma + QomaTests target).

## Step 2 - Build universal binary

Build terpisah untuk arm64 dan x86_64, lalu gabungkan dengan `lipo`:

```bash
# Arm64
xcodebuild -project qoma.xcodeproj -scheme Qoma -configuration Release \
  -arch arm64 -derivedDataPath /tmp/qoma-arm64 build

# x86_64
xcodebuild -project qoma.xcodeproj -scheme Qoma -configuration Release \
  -arch x86_64 -derivedDataPath /tmp/qoma-x64 build

# Gabungkan jadi universal binary
lipo -create \
  /tmp/qoma-arm64/Build/Products/Release/Qoma.app/Contents/MacOS/Qoma \
  /tmp/qoma-x64/Build/Products/Release/Qoma.app/Contents/MacOS/Qoma \
  -output /tmp/qoma-universal-binary

# Verifikasi
lipo -info /tmp/qoma-universal-binary
# Output: Architectures in the fat file: ... are: x86_64 arm64
```

## Step 3 - Bungkus universal app

```bash
mkdir -p /Users/kiram/Code/qoma-release
cp -R /tmp/qoma-arm64/Build/Products/Release/Qoma.app /Users/kiram/Code/qoma-release/Qoma.app
cp /tmp/qoma-universal-binary /Users/kiram/Code/qoma-release/Qoma.app/Contents/MacOS/Qoma
codesign --force --sign - /Users/kiram/Code/qoma-release/Qoma.app
```

## Step 4 - Buat DMG

```bash
create-dmg \
  --overwrite \
  --volname "Qoma" \
  --dmg-title "qoma" \
  --dmg-name "qoma-1.1.0-mac-universal" \
  /Users/kiram/Code/qoma-release/Qoma.app \
  /Users/kiram/Code/qoma-release

# Rename (create-dmg auto-append version, hapus spasi)
mv "/Users/kiram/Code/qoma-release/Qoma 1.1.0.dmg" \
  /Users/kiram/Code/qoma-release/qoma-1.1.0-mac-universal.dmg
```

> Note: Warning "Code signing failed" dari `create-dmg` bisa diabaikan — DMG tetap valid, hanya tidak Apple-signed.

Ambil SHA256:

```bash
shasum -a 256 /Users/kiram/Code/qoma-release/qoma-1.1.0-mac-universal.dmg
```

## Step 5 - GitHub Release

Di repo `BroKarim/qoma`:

```bash
git add -A && git commit -m "Release v1.1.0"
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

Buat GitHub Release dari tag `v1.1.0`, upload `qoma-1.1.0-mac-universal.dmg`.

## Step 6 - Update Homebrew tap

Di repo `BroKarim/homebrew-qoma`, update `Casks/qoma.rb`:

```ruby
cask "qoma" do
  version "1.1.0"
  sha256 "SHA256_DARI_DMG"
  url "https://github.com/BroKarim/qoma/releases/download/v#{version}/qoma-#{version}-mac-universal.dmg"
  # ...
end
```

Commit & push.

---

## What's new (v1.1.0)

- Extensions system: toggle-based Feature Extensions (Todolist as first extension)
- Dynamic floating panel: collapsed/expanded states with morph transitions
- Extensions settings pane with dynamic card grid
- Analytics integration for extension data
