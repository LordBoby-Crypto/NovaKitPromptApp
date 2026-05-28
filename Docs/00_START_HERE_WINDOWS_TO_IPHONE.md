# Start Here: Windows Laptop + iPhone Real-App Route

This package is designed for your exact situation: you want a real iPhone app, you have a Windows laptop, and you do not have a Mac.

## What you can do from Windows

You can:

1. Create a GitHub repository.
2. Upload this project.
3. Configure GitHub Actions.
4. Trigger a cloud macOS build.
5. Download an IPA artifact or upload the app to TestFlight.
6. Install the result on your iPhone.

## What cannot happen entirely on the iPhone

You cannot take SwiftUI source code, tap it on your iPhone, and permanently install it as a normal iOS app without Apple signing/distribution. Apple requires iOS apps to be signed. GitHub Actions provides the cloud Mac needed for the build step.

## Recommended path

Use this order:

### Best long-term path

**GitHub Actions -> TestFlight**

Use this if you can get or already have an Apple Developer Program account.

Pros:
- Most normal iPhone install experience.
- Installs through TestFlight.
- Easier to update later.
- No weekly sideload refresh headache.

Cons:
- Apple Developer Program is required.
- More setup steps.

### Backup path

**GitHub Actions -> unsigned IPA -> Sideloadly on Windows**

Use this if you want to experiment before doing TestFlight.

Pros:
- Uses Windows for install.
- Does not require App Store/TestFlight flow.

Cons:
- More fragile.
- Free Apple ID installs may expire.
- Device trust/developer mode steps may be needed.
- The IPA might need Sideloadly to sign it.

## What to do first

1. Create a free GitHub account if you do not have one.
2. Unzip this package on your Windows laptop.
3. Follow `Docs/01_GITHUB_REPO_SETUP.md`.
4. Choose TestFlight or Sideloadly path.
