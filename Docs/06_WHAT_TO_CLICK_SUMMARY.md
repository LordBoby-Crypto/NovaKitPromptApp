# 06 - What to Click Summary

## If using TestFlight

1. Upload this project to GitHub.
2. Create Apple Developer Bundle ID.
3. Create App Store Connect app record.
4. Create Distribution certificate and App Store provisioning profile.
5. Create App Store Connect API key.
6. Add GitHub secrets.
7. GitHub repo -> Actions -> Build and Upload to TestFlight -> Run workflow.
8. App Store Connect -> TestFlight -> add yourself as tester.
9. iPhone -> TestFlight -> install app.

## If using Sideloadly

1. Upload this project to GitHub.
2. GitHub repo -> Actions -> Build Unsigned IPA Artifact for Windows Sideloading -> Run workflow.
3. Download IPA artifact on Windows.
4. Open Sideloadly.
5. Plug in iPhone.
6. Install IPA.
7. Trust/Developer Mode if prompted.

## Updating the app already installed on your iPhone

1. Keep the same `BUNDLE_ID` secret you used for the first install. iOS treats matching bundle IDs as updates instead of a separate app.
2. Commit/push the app changes to GitHub.
3. GitHub repo -> Actions -> Build and Upload to TestFlight -> Run workflow.
4. Fastlane automatically raises the build number using the current timestamp, so TestFlight sees it as a newer build.
5. iPhone -> TestFlight -> open NovaKit -> Update.

If you are using the unsigned IPA/Sideloadly path, run the unsigned IPA workflow again, download the new IPA artifact, and install it with the same Apple ID/signing setup. TestFlight is still the smoother update path.

## Optional App Store Connect metadata upload

If you want the TestFlight workflow to upload the metadata files in `fastlane/metadata/en-US`, add a GitHub Actions repository variable named `UPLOAD_APP_METADATA` and set it to `true`. Leave it unset or set it to `false` if you only want to upload builds.
