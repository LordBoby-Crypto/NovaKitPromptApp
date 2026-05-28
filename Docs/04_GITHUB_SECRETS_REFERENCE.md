# 04 - GitHub Secrets Reference

Add these under:

```text
GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret
```

## Required for TestFlight workflow

### APPLE_ID_EMAIL
Your Apple ID email.

Example:

```text
you@example.com
```

### APPLE_TEAM_ID
Your Apple Developer Team ID.

Usually found in Apple Developer account membership details.

### APP_STORE_CONNECT_TEAM_ID
Your App Store Connect team ID.

May be the same as the Developer Team ID in simple accounts, but not always.

### BUNDLE_ID
Your app bundle identifier.

Example:

```text
com.zacmarlin.novakitpromptapp
```

### PROVISIONING_PROFILE_NAME
The profile name embedded in the App Store provisioning profile.

Example:

```text
NovaKitPromptApp AppStore
```

### BUILD_CERTIFICATE_BASE64
Base64 text of your iOS Distribution `.p12` certificate.

Create on Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios_distribution.p12")) | Set-Content cert_base64.txt
```

### BUILD_PROVISION_PROFILE_BASE64
Base64 text of your `.mobileprovision` App Store provisioning profile.

Create on Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("NovaKitPromptApp.mobileprovision")) | Set-Content profile_base64.txt
```

### P12_PASSWORD
Password used when exporting the `.p12` certificate.

### KEYCHAIN_PASSWORD
Any strong temporary password for the GitHub Actions build keychain.

Example:

```text
Use-a-long-random-password-here-12345
```

### ASC_KEY_ID
App Store Connect API key ID.

### ASC_ISSUER_ID
App Store Connect API issuer ID.

### ASC_PRIVATE_KEY
The full private key content from the `.p8` App Store Connect API key file.

It should include lines like:

```text
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
```

Paste the whole thing as the secret value.

## Required for unsigned sideload workflow

No Apple secrets are required for the unsigned IPA artifact workflow.

But that IPA still has to be signed/installed by Sideloadly or another sideloading tool before it will run on an iPhone.
