# Ikigai Atlas for iPhone

A native iOS app that guides anyone through six stages to map their own ikigai (生き甲斐), the Japanese idea of what makes life worth living. Every result is built only from the person's own stories, ratings and words, so no two atlases are alike.

The framework follows the Japanese understanding of ikigai rather than the popular four-circle diagram:

- **Mieko Kamiya** (1966): ikigai is both the *sources* of worth and *ikigai-kan*, the felt sense that life is worth living, which depends on seven needs.
- **Gordon Mathews**: ikigai lives between belonging to a group or role (ittaikan) and self-realisation (jiko jitsugen).
- **Ken Mogi**: start small, and notice the joy of little things.
- **Akihiro Hasegawa**: small daily joys add up, and ikigai can live in the past, present and future.

The four-circle diagram (Zuzunaga 2011, relabelled "ikigai" by Marc Winn in 2014) is included as an optional, clearly labelled work lens.

## What's inside

| Part | What it does |
|---|---|
| `Packages/IkigaiCore` | The framework as a platform-independent Swift package: data model, completion rules, Kamiya's three authenticity tests, needs coverage, insights, recurring words, source suggestions, source-map geometry and Markdown export. Unit tests check its results against the tested web version. |
| `App/Design` | The design layer. Microsoft's [Fluent 2 iOS](https://github.com/microsoft/fluentui-apple) tokens re-themed with the atlas palette (aizome indigo, shell-white paper, sumi ink), plus Fluent buttons, pills, progress bar and activity indicator. |
| `App/Features` | SwiftUI screens: Journey (the six stages), Atlas, Learn, Welcome and Settings. |
| `App/Services` | Storage (SwiftData, with optional iCloud sync through CloudKit), on-device pattern reading with Apple Intelligence, local reminders, Face ID lock and PDF/text export. |
| `AppStore` | Draft privacy policy and App Store listing. |

**Design system:** Fluent 2 (MIT licence) for tokens and controls, layered on native SwiftUI navigation, lists, forms and sheets so the app behaves like a first-party iPhone app (Dynamic Type, VoiceOver, dark mode, iOS 26 glass bars, haptics). Display type is Shippori Mincho B1 (SIL Open Font Licence), subset to the characters the app uses; everything else uses Apple's system font.

**Privacy:** answers stay on the iPhone and, when iCloud sync is on, in the person's own private iCloud database. There are no accounts, no analytics and no server. The optional pattern reading runs on the device's own Apple Intelligence model.

## Run it on your Mac (no Terminal needed)

You need **Xcode 26 or later**, free from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835). Xcode 26 needs **macOS Sequoia 15.6 or later** (Xcode 26.4 and later need macOS Tahoe 26.2). To check your Mac, open  menu → About This Mac.

1. On this page, click the green **Code** button, then **Download ZIP**. Double-click the ZIP in your Downloads folder to unzip it.
2. Open the unzipped folder and double-click **IkigaiAtlas.xcodeproj**. If Xcode asks whether to trust the package, choose **Trust & Open**.
3. Wait until the bar at the top of Xcode stops saying **Fetching packages** or **Resolving packages** (a minute or two the first time).
4. At the top of the window, click the device name next to **IkigaiAtlas** and choose an iPhone simulator, for example **iPhone 17 Pro**.
5. Press **▶︎** (or ⌘R). The simulator opens and the app launches.

### On your own iPhone, with a free Apple ID

1. In Xcode, open **Xcode → Settings → Accounts** and add your Apple ID.
2. In the left sidebar, click **IkigaiAtlas** (the blue icon at the top), choose the **IkigaiAtlas** target, open **Signing & Capabilities** and pick your team, for example "Your Name (Personal Team)".
3. Connect your iPhone with a cable and choose it at the top of the window. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode** and restart when asked.
4. Press **▶︎**. The first time, the iPhone says the developer isn't trusted: open **Settings → General → VPN & Device Management**, tap your Apple ID and tap **Trust**, then press **▶︎** again.

Free accounts can install for 7 days at a time; press **▶︎** again to renew.

### If it doesn't run

| What you see | What to do |
|---|---|
| **Cannot find 'UIGlassEffect' in scope**, or many errors inside **FluentUI** | Your Xcode is older than 26. Update Xcode from the Mac App Store; if your Mac can't run Xcode 26, it needs macOS Sequoia 15.6 or later. |
| **The project cannot be opened** or **is damaged** | Your Xcode is too old. Update to Xcode 26 or later. |
| **Signing for "IkigaiAtlas" requires a development team** | You chose a real iPhone. Pick a simulator, or follow "On your own iPhone" above. |
| **Failed to register bundle identifier** / **is not available** | Someone else's account uses this ID. In `Config/App.xcconfig` change `PRODUCT_BUNDLE_IDENTIFIER` to something unique, for example `com.yourname.ikigaiatlas`. |
| **Missing package product 'FluentUI'** | Choose **File → Packages → Reset Package Caches**, wait for packages to finish fetching, then press **▶︎**. |
| **Personal development teams do not support iCloud** | iCloud sync was switched on. Set `IKIGAI_ICLOUD_SYNC = NO` in `Config/App.xcconfig`. |

### Turning on iCloud sync

iCloud sync needs a paid [Apple Developer Program](https://developer.apple.com/programs/) membership (US$99 a year), so it's off by default and the app saves on the device only. With a paid membership, set `IKIGAI_ICLOUD_SYNC = YES` in `Config/App.xcconfig`, choose your team in Signing & Capabilities, and run again. The app then syncs each person's atlas through their own private iCloud database.

### For developers

- `project.yml` is the source of truth for the Xcode project ([XcodeGen](https://github.com/yonaskolb/XcodeGen)). GitHub regenerates and commits `IkigaiAtlas.xcodeproj` whenever files are added or removed. To do it yourself: `brew install xcodegen && xcodegen`.
- Bundle ID, team and the iCloud switch live in `Config/App.xcconfig`.
- Requirements: iOS 17 or later on the iPhone. Pattern reading needs iOS 26 on an iPhone with Apple Intelligence (iPhone 15 Pro or newer); everything else works without it. App Store uploads must be built with Xcode 26 or later.

## Tests and builds

Every push runs these checks on GitHub's Mac runners:

- **Framework logic tests**: `swift test --package-path Packages/IkigaiCore`
- **iOS app build**: generates the project and builds it for the iOS Simulator
- **Fresh Mac build**: builds the committed `IkigaiAtlas.xcodeproj` with no team and no signing changes, on macOS 15 and macOS 26 with their newest Xcode, exactly as someone opening the ZIP would

After every green build on `main`, a third workflow runs the app in an iPhone simulator and publishes screenshots of every screen, in light and dark, to the [`screenshots` branch](https://github.com/walecalfos/ikigai-atlas-ios/tree/screenshots). It also exports the example atlas to PDF to check that sharing works.

Run the logic tests locally with `swift test --package-path Packages/IkigaiCore`.

To open any screen filled with the fictional example atlas (useful for App Store screenshots), add launch arguments in Xcode under **Product → Scheme → Edit Scheme → Run → Arguments**: `-uiScreenshot atlas` (or `welcome`, `journey`, `pulse`, `remember`, `notice`, `gather`, `source`, `weave`, `live`, `example`, `learn`, `settings`), optionally with `-uiScrollTo insights` to jump to a section. Screenshot mode never touches real data.

## Release checklist

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) (US$99 a year) and set `IKIGAI_ICLOUD_SYNC = YES` in `Config/App.xcconfig`.
2. In [App Store Connect](https://appstoreconnect.apple.com), create the app with the same bundle identifier.
3. Publish the privacy policy in `AppStore/privacy-policy.md` at a public URL and add it to the listing.
4. Fill in the listing from `AppStore/listing.md`, the age rating questionnaire and the App Privacy section ("Data Not Collected").
5. Take screenshots on a 6.9-inch iPhone simulator (for example iPhone 17 Pro Max) using screenshot mode above. The images on the `screenshots` branch are 6.3-inch, fine for review but not the size App Store Connect asks for first.
6. In Xcode choose **Product → Archive**, then **Distribute App → App Store Connect**. Test with TestFlight, then submit for review.

## Licences

- App code: © the repository owner.
- [Fluent UI Apple](https://github.com/microsoft/fluentui-apple): MIT licence, © Microsoft.
- [Shippori Mincho B1](https://github.com/fontdasu/ShipporiMincho): SIL Open Font Licence 1.1, see `App/Resources/Fonts/OFL.txt`.
