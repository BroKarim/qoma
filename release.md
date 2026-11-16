# Qyube v1.0.0 release

Direct macOS distribution from the official website. The release artifact is a Developer ID-signed, notarized and stapled DMG. Sparkle updates are disabled in v1.0.0 until the Qyube appcast host and EdDSA public/private keys are configured.

## One-time setup

1. Create a **Developer ID Application** certificate for the Qyube bundle identifier and install it in the release Mac keychain.
2. Store Apple notarization credentials with `xcrun notarytool store-credentials QyubeNotary --apple-id ... --team-id ... --password ...`. The password is an app-specific password; use the keychain profile rather than saving credentials in this repository.
3. Ensure the expected team has the Qyube app identifier, entitlements, and signing certificate. Set `DEVELOPER_ID_APPLICATION` to the certificate's exact identity, `APPLE_TEAM_ID` to the 10-character team ID, and `NOTARYTOOL_PROFILE` to the saved keychain profile.
4. Configure a GitHub CLI login with permission to create or upload releases for `BroKarim/qoma`.

## Release v1.0.0

From the repository root on a clean, reviewed release commit:

```sh
export DEVELOPER_ID_APPLICATION='Developer ID Application: <legal seller> (<TEAMID>)'
export APPLE_TEAM_ID='<TEAMID>'
export NOTARYTOOL_PROFILE='QyubeNotary'
scripts/release.sh v1.0.0
```

The script archives the Release target, exports the signed app, verifies the signature, submits an app ZIP and DMG to Apple notarization, staples both accepted artifacts, creates a SHA-256 checksum, then creates or updates the matching GitHub Release with the DMG and checksum. It contains no credentials. Review the exported app, notarization logs, and release page before announcing the download.

The website download link must point to the signed DMG asset. Do not publish an ad-hoc build or instruct customers to remove Gatekeeper quarantine.

## Future Sparkle appcast

Sparkle remains disabled (`QyubeEnableSparkleUpdates=false`) until all of these are ready: a permanent Qyube HTTPS appcast URL, an EdDSA signing key stored outside Git, the matching `SUPublicEDKey` in the signed app, and an automated feed-generation/upload step using Sparkle's `generate_appcast` tool. At that point, set the feed URL and public key in the release build configuration, enable the updater, generate and sign the appcast for each release, upload the feed and artifacts, and verify update discovery on a clean installed copy. Do not re-enable the Qoma/Pomodoro feed or ship an empty feed.

## Version and checks

`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` should be reviewed in the Xcode project before each release. For v1.0.0, keep the public product name **Qyube**. Run the complete website and macOS release checks before creating a GitHub release.
