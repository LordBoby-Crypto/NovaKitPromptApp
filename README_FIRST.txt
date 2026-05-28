NovaKit iOS Windows CloudBuild Package
=====================================

Goal
----
This package is for getting a real iPhone app installed while using only a Windows laptop and an iPhone.

Important truth
---------------
You do not need to own a Mac, but iOS apps still must be built on macOS somewhere. This package uses GitHub Actions macOS cloud runners to do that build step.

Two paths are included:

1. Clean path: GitHub Actions -> TestFlight
   - Best install experience.
   - Requires Apple Developer Program membership.
   - Requires App Store Connect setup.
   - Installs through the TestFlight app on your iPhone.

2. Rougher path: GitHub Actions -> unsigned IPA artifact -> Sideloadly on Windows
   - Can avoid TestFlight.
   - Still not as clean or stable.
   - Usually needs refresh/reinstall behavior depending on signing.
   - The unsigned IPA may need Sideloadly to sign it with your Apple ID.

Start here
----------
Read these files in order:

1. Docs/00_START_HERE_WINDOWS_TO_IPHONE.md
2. Docs/01_GITHUB_REPO_SETUP.md
3. Docs/02_TESTFLIGHT_PATH_DETAILED.md
4. Docs/03_SIDELOADLY_PATH_DETAILED.md
5. Docs/04_GITHUB_SECRETS_REFERENCE.md
6. Docs/05_TROUBLESHOOTING.md

What is already included
------------------------
- Native SwiftUI iPhone app source.
- GitHub Actions workflows.
- Fastlane TestFlight lane.
- App Store Connect metadata templates.
- Windows helper scripts.
- Step-by-step setup guides.
