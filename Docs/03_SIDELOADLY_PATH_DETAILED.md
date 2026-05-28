# 03 - Sideloadly Path Detailed Guide

This path tries to get a real app onto your iPhone from Windows without TestFlight.

## What this path does

1. GitHub Actions builds an unsigned IPA artifact on a macOS runner.
2. You download the IPA on your Windows laptop.
3. You use Sideloadly to install/sign it onto your iPhone.

## Important warning

This is not as clean as TestFlight.

Free Apple ID sideloading can expire and may need refreshing or reinstalling. You may also need iPhone Developer Mode enabled. Use this path only if you accept that it may be annoying.

## Step 1 - Build the unsigned IPA

1. Open your GitHub repo.
2. Click **Actions**.
3. Click **Build Unsigned IPA Artifact for Windows Sideloading**.
4. Click **Run workflow**.
5. Wait for the workflow to finish.
6. Open the finished workflow run.
7. Download the artifact named:

```text
NovaKitPromptApp-unsigned-IPA
```

8. Unzip the artifact on your Windows laptop.
9. You should see:

```text
NovaKitPromptApp-unsigned.ipa
```

## Step 2 - Install Sideloadly on Windows

1. Download Sideloadly from the official Sideloadly site.
2. Install the version for Windows.
3. If Sideloadly asks for Apple components, follow its instructions exactly.

## Step 3 - Install to iPhone

1. Plug your iPhone into your Windows laptop.
2. Trust the computer on your iPhone if prompted.
3. Open Sideloadly.
4. Drag `NovaKitPromptApp-unsigned.ipa` into Sideloadly.
5. Enter your Apple ID if requested.
6. Start the sideload.
7. Follow any on-screen prompts.

## Step 4 - Trust/Developer Mode on iPhone

Depending on your iOS version, you may need to:

- Enable Developer Mode.
- Trust the developer profile.
- Reopen the app after trust is complete.

Look under:

```text
Settings -> Privacy & Security -> Developer Mode
```

and/or:

```text
Settings -> General -> VPN & Device Management
```

The exact wording can vary by iOS version.

## If it fails

Use the TestFlight path if possible. Sideloading is more fragile than TestFlight.
