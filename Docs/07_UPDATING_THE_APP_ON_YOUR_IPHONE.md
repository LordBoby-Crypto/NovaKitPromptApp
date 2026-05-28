# 07 - Updating the App on Your iPhone

Use this when we make changes in this repo and you want the updated app on the same iPhone.

## The simple rule

Keep the same Bundle ID every time.

If the app already installed on your phone uses `com.zacmarlin.novakitpromptapp`, then future builds should use that same Bundle ID unless you intentionally want a second separate app.

## If you installed through TestFlight

1. Commit and push the new code to GitHub.
2. Open GitHub -> your repo -> Actions.
3. Run **Build and Upload to TestFlight**.
4. Wait for Apple processing to finish in App Store Connect.
5. Open TestFlight on your iPhone.
6. Tap **Update**.

The workflow automatically increments the build number using the current timestamp, so TestFlight should accept repeated updates.

## If you installed with Sideloadly

1. Commit and push the new code to GitHub.
2. Open GitHub -> your repo -> Actions.
3. Run **Build Unsigned IPA Artifact for Windows Sideloading**.
4. Download the new IPA artifact.
5. Install it again with Sideloadly using the same Apple ID/signing setup.

If iOS treats it as a different app, check that the Bundle ID used by Sideloadly matches the previous install.

## Data safety before big updates

Inside the app, tap the export/share button on the conversation list and save a backup JSON before major changes. The app now exports a versioned backup envelope so future schema changes can migrate older conversation data.

## Good update habit

Before each update, make a small note of:

- What changed.
- Which workflow you ran.
- The date of the build.
- Whether the app updated cleanly on your phone.
