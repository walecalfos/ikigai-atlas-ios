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
| `App/Services` | iCloud-synced storage (SwiftData + CloudKit), on-device pattern reading with Apple Intelligence, local reminders, Face ID lock and PDF/text export. |
| `AppStore` | Draft privacy policy and App Store listing. |

**Design system:** Fluent 2 (MIT licence) for tokens and controls, layered on native SwiftUI navigation, lists, forms and sheets so the app behaves like a first-party iPhone app (Dynamic Type, VoiceOver, dark mode, iOS 26 glass bars, haptics). Display type is Shippori Mincho B1 (SIL Open Font Licence), subset to the characters the app uses; everything else uses Apple's system font.

**Privacy:** answers stay on the iPhone and in the person's own private iCloud database. There are no accounts, no analytics and no server. The optional pattern reading runs on the device's own Apple Intelligence model.

## Requirements

- A Mac with **Xcode 26 or later** (required by Apple for App Store uploads since 28 April 2026).
- **iOS 17 or later** on the iPhone. Pattern reading needs iOS 26 on an iPhone with Apple Intelligence (iPhone 15 Pro or newer); everything else works without it.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project: `brew install xcodegen`.

## Run it on your Mac

```bash
git clone https://github.com/walecalfos/ikigai-atlas-ios.git
cd ikigai-atlas-ios
brew install xcodegen      # once
xcodegen                   # creates IkigaiAtlas.xcodeproj
open IkigaiAtlas.xcodeproj
```

In Xcode:

1. Select the **IkigaiAtlas** target, open **Signing & Capabilities** and choose your **Team**.
2. If the bundle identifier `com.walecalfos.ikigaiatlas` is taken, change it, and change the iCloud container to match (`iCloud.<your bundle id>`) in `project.yml`, then run `xcodegen` again.
3. Pick an iPhone simulator or your own iPhone and press **Run**.

**Free Apple ID?** You can run the app on your own iPhone without the paid developer programme, but free accounts can't use iCloud. Remove the **iCloud** and **Push Notifications** capabilities in Signing & Capabilities first; the app then saves on the device only.

## Tests and builds

Every push runs two checks on GitHub's Mac runners (see `.github/workflows/ci.yml`):

- **Framework logic tests**: `swift test --package-path Packages/IkigaiCore`
- **iOS app build**: generates the project and builds it for the iOS Simulator

After every green build on `main`, a third workflow runs the app in an iPhone simulator and publishes screenshots of every screen, in light and dark, to the [`screenshots` branch](https://github.com/walecalfos/ikigai-atlas-ios/tree/screenshots). It also exports the example atlas to PDF to check that sharing works.

Run the logic tests locally with `swift test --package-path Packages/IkigaiCore`.

To open any screen filled with the fictional example atlas (useful for App Store screenshots), add launch arguments in Xcode under **Product → Scheme → Edit Scheme → Run → Arguments**: `-uiScreenshot atlas` (or `welcome`, `journey`, `pulse`, `remember`, `notice`, `gather`, `source`, `weave`, `live`, `example`, `learn`, `settings`), optionally with `-uiScrollTo insights` to jump to a section. Screenshot mode never touches real data.

## Release checklist

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) (US$99 a year).
2. In [App Store Connect](https://appstoreconnect.apple.com), create the app with the same bundle identifier.
3. Publish the privacy policy in `AppStore/privacy-policy.md` at a public URL and add it to the listing.
4. Fill in the listing from `AppStore/listing.md`, the age rating questionnaire and the App Privacy section ("Data Not Collected").
5. Take screenshots on a 6.9-inch iPhone simulator (for example iPhone 17 Pro Max) using screenshot mode above. The images on the `screenshots` branch are 6.3-inch, fine for review but not the size App Store Connect asks for first.
6. In Xcode choose **Product → Archive**, then **Distribute App → App Store Connect**. Test with TestFlight, then submit for review.

## Licences

- App code: © the repository owner.
- [Fluent UI Apple](https://github.com/microsoft/fluentui-apple): MIT licence, © Microsoft.
- [Shippori Mincho B1](https://github.com/fontdasu/ShipporiMincho): SIL Open Font Licence 1.1, see `App/Resources/Fonts/OFL.txt`.
