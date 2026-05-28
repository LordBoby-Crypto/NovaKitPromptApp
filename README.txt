NovaKit Prompt App - Native iPhone Version

This is a real native iOS SwiftUI app project, not a webpage/PWA.

What it does:
- Creates NovaKit v3.1 starter prompts.
- Saves multiple conversations.
- Lets you paste AI/Nova responses.
- Lets you attach files created by the AI.
- Uses the pasted response plus attached file text when creating the next follow-up prompt.
- Stores data locally on the iPhone using app storage.
- Can export/import conversation backups as JSON.

How to install on iPhone with Xcode:
1. Use a Mac with Xcode installed.
2. Unzip this folder.
3. Open NovaKitPromptApp.xcodeproj.
4. In Xcode, click the NovaKitPromptApp project.
5. Go to Signing & Capabilities.
6. Select your Apple ID team.
7. If needed, change Bundle Identifier from com.zacmarlin.novakitpromptapp to something unique, like com.yourname.novakitpromptapp.
8. Connect your iPhone with USB or use wireless debugging.
9. Select your iPhone as the run destination.
10. Click Run.
11. On your iPhone, trust your developer profile if iOS asks.

Limits:
- This package is source code, not a signed IPA.
- I cannot sign the app with your Apple ID from here.
- For TestFlight/App Store distribution, you need an Apple Developer Program account and App Store Connect setup.
- The project includes a placeholder app icon. You can replace it in Assets.xcassets/AppIcon.appiconset.

Notes:
- The app is fully offline.
- It does not call any AI service itself.
- It creates prompts for you to paste into your NovaKit v3.1 AI.
