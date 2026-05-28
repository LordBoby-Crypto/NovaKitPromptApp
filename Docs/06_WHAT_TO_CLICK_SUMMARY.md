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
