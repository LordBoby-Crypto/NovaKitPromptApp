# 01 - GitHub Repo Setup from Windows

## Goal

Put this iOS project into GitHub so GitHub Actions can build it on a cloud macOS runner.

## Simple web-upload method

1. Go to GitHub on your Windows laptop.
2. Create a new repository.
   - Name: `NovaKitPromptApp`
   - Visibility: private is recommended.
3. Open the repository page.
4. Click **Add file** -> **Upload files**.
5. Drag all contents of the `NovaKit_iOS_Windows_CloudBuild` folder into GitHub.
6. Commit the files.

Make sure these files appear in the repo root:

- `NovaKitPromptApp.xcodeproj`
- `NovaKitPromptApp/`
- `.github/workflows/testflight.yml`
- `.github/workflows/unsigned_ipa_for_sideloading.yml`
- `fastlane/Fastfile`
- `Gemfile`

## Better Git method, if you use Git on Windows

Open PowerShell inside this folder and run:

```powershell
git init
git add .
git commit -m "Initial NovaKit iOS app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/NovaKitPromptApp.git
git push -u origin main
```

## After upload

Open the repo on GitHub, then click:

**Actions**

You should see two workflows:

- **Build and Upload to TestFlight**
- **Build Unsigned IPA Artifact for Windows Sideloading**
