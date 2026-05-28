NovaKit Prompt App - Native iPhone Version

This is a real native iOS SwiftUI app project, not a webpage/PWA.

What it does:
- Creates NovaKit v3.1 starter prompts.
- Uses a chat-style thread instead of one crowded prompt-builder page.
- Lets you paste each AI/Nova response at the bottom of the thread and attach files created by the AI.
- Generates a NovaKit guidance message that explains the response/files and gives a copy-ready next prompt.
- Saves multiple conversations with folders, tags, and archive support.
- Stores data locally on the iPhone using app storage.
- Can export/import versioned conversation backups as JSON.
- Uses a cleaner chat-style workflow for starter prompts, AI replies, attached files, and generated NovaKit response prompts.
- Supports tags, archived conversations, richer prompt modes, configurable prompt-template behavior, copy feedback, sharing, attachment previews, and haptics.

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
- To update an already installed iPhone copy, keep the same Bundle ID and rerun the TestFlight or Sideloadly workflow described in Docs/07_UPDATING_THE_APP_ON_YOUR_IPHONE.md.
