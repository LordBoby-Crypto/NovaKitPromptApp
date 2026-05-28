# 02 - TestFlight Path Detailed Guide

This is the cleanest way to get a real app on your iPhone without owning a Mac.

## Requirements

You need:

1. Apple Developer Program membership.
2. App Store Connect access.
3. A Bundle ID for the app.
4. An iOS Distribution certificate as `.p12`.
5. An App Store provisioning profile as `.mobileprovision`.
6. An App Store Connect API key.
7. GitHub repository secrets.

## Suggested Bundle ID

Use a unique bundle ID, for example:

```text
com.zacmarlin.novakitpromptapp
```

If that exact ID is unavailable, use your own variant.

## App Store Connect app record

Create a new app record in App Store Connect:

- Platform: iOS
- Name: NovaKit Prompt App
- Bundle ID: the Bundle ID you created
- SKU: NOVAKITPROMPTAPP001
- User Access: Full Access, unless you know you need limited access

## GitHub Secrets needed

Open your GitHub repo, then go to:

**Settings -> Secrets and variables -> Actions -> New repository secret**

Create these secrets:

```text
APPLE_ID_EMAIL
APPLE_TEAM_ID
APP_STORE_CONNECT_TEAM_ID
BUNDLE_ID
PROVISIONING_PROFILE_NAME
BUILD_CERTIFICATE_BASE64
BUILD_PROVISION_PROFILE_BASE64
P12_PASSWORD
KEYCHAIN_PASSWORD
ASC_KEY_ID
ASC_ISSUER_ID
ASC_PRIVATE_KEY
```

See `Docs/04_GITHUB_SECRETS_REFERENCE.md` for what each secret means.

## Convert certificate/profile to Base64 on Windows

Use PowerShell in the folder containing your files.

For the `.p12` certificate:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios_distribution.p12")) | Set-Content cert_base64.txt
```

For the provisioning profile:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("NovaKitPromptApp.mobileprovision")) | Set-Content profile_base64.txt
```

Open each `.txt` file, copy the full text, and paste it into the matching GitHub secret.

## Run the TestFlight workflow

1. Open your GitHub repo.
2. Click **Actions**.
3. Click **Build and Upload to TestFlight**.
4. Click **Run workflow**.
5. Wait for it to finish.

If successful, a build appears in App Store Connect / TestFlight after Apple processing.

## Install on iPhone

1. Install the TestFlight app from the App Store.
2. In App Store Connect, add yourself as a tester.
3. Accept the invite on your iPhone.
4. Install NovaKit Prompt App through TestFlight.

## Notes

- First TestFlight build processing can take time.
- Apple may require beta review for external testers.
- Internal testers are easier if your Apple ID is on the App Store Connect team.
