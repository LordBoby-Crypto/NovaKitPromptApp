# 05 - Troubleshooting

## GitHub Actions says scheme not found

Check that the repo root contains:

```text
NovaKitPromptApp.xcodeproj
```

The workflow assumes the project is in the root, not inside another folder.

## TestFlight upload says bundle ID does not match

The Bundle ID in Xcode project, provisioning profile, and GitHub secret must match.

Check:

```text
BUNDLE_ID
```

and your Apple Developer identifier.

## Code signing failed

Most likely causes:

- Wrong certificate type.
- Wrong provisioning profile.
- `.p12` password wrong.
- Base64 copy included missing characters or extra formatting.
- Provisioning profile does not include the Bundle ID.

## Fastlane API key failed

Most likely causes:

- `ASC_KEY_ID` wrong.
- `ASC_ISSUER_ID` wrong.
- `ASC_PRIVATE_KEY` missing BEGIN/END PRIVATE KEY lines.
- API key lacks App Manager/Admin access.


## TestFlight upload says bundle version must be higher than previously uploaded version

This means App Store Connect received an IPA whose `CFBundleVersion` was not higher than the previous uploaded build.

The TestFlight workflow now avoids `agvtool` and writes a UTC timestamp build number directly into `NovaKitPromptApp/Info.plist` before Fastlane builds the IPA.

What to do:

1. Pull or upload the latest repo changes.
2. Run **Build and Upload to TestFlight** again.
3. Confirm the Fastlane log prints a line like `Using CFBundleShortVersionString=1.0 and CFBundleVersion=20260528225345`.
4. If it still fails, make sure the new `CFBundleVersion` number in the log is greater than the newest build number listed in App Store Connect -> TestFlight.

## TestFlight build uploaded but not visible yet

Wait. Apple processes builds after upload. It can take a while.

## Sideloadly install fails

Try these:

1. Update iTunes/iCloud components if Sideloadly asks.
2. Trust the computer on your iPhone.
3. Enable Developer Mode on iPhone.
4. Try a different cable.
5. Rebuild the unsigned IPA.
6. Use TestFlight instead if you can.
