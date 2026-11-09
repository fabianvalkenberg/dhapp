# DH App — Den Haag Gemeente App

Native iOS-app voor de gemeente Den Haag, gebouwd in **SwiftUI** met Xcode.
Prototype/demo-karakter: data is grotendeels dummy/hardcoded, DigiD is nagebootst.

---

## Tech stack

- **SwiftUI** (deployment target iOS 17) — géén web framework, géén Next.js/React, géén npm
- **Xcode / xcodebuild** als build tool; **XcodeGen** (`project.yml`) genereert het `.xcodeproj`
- **MapKit** voor de Buurt-kaart, met externe **CARTO Positron**-tiles (no-labels)
- **Firebase/Firestore** voor onboarding-logging én volledige **sessie-analytics**
  (project `denhaag-app-fappie`)
- **LanguageManager** — vertalingen NL/EN/TR, dictionary-based
- **UserDefaults** voor instellingen (tegelselectie, werkadres, taal, naam, buurt-onderwerpen)
- **ClaudeService** — AI-chat in de Regelen-assistent (API-key via `APIConfig`)
- **`dashboard/`** — los Node-project (firebase-admin) dat een testverslag-dashboard
  rendert; **live op Vercel** (https://dashboard-tau-pink-91.vercel.app)

## Structuur

```
DH app/
├── DenHaag/
│   ├── DenHaag.xcodeproj     ← gegenereerd door XcodeGen (niet handmatig editen)
│   ├── project.yml           ← bron van waarheid voor target/Info.plist/versie
│   ├── ExportOptions.plist
│   └── DenHaag/              ← source
│       ├── DenHaagApp.swift  ← @main; splash → onboarding-gate → MainTabView
│       ├── Models/           ← AppTheme, HomeSettings, FontDebug
│       ├── Services/         ← LanguageManager, ClaudeService, OnboardingLogService,
│       │                        AnalyticsService, SpeechService, APIConfig
│       └── Views/
│           ├── MainTabView.swift   ← tab-container + alle detail-overlays
│           ├── HomeView.swift, RegelenView.swift, HelpView.swift
│           ├── AanvraagDetailView.swift  ← status-aanvraag (progress + pulserend puntje)
│           ├── FeedbackView.swift  ← gestapte feedback-flow (keyboard-aware)
│           ├── Onboarding/         ← OnboardingView (7 stappen: DigiD-mock + naam + voorkeuren)
│           ├── Buurt/              ← BuurtView, BuurtMapView, BuurtCardView,
│           │                          BuurtDetailView, NeighbourhoodItem, RadarPulseView
│           └── Components/         ← TegelView, BottomTabBar, HeaderView, PassenView,
│                                      BackCircleButton, MarqueeTilesView, NotchShape, …
├── dashboard/  ← Node/Vercel testverslag-dashboard (firebase-admin, los van de app)
├── firebase/   ← firestore.rules (sessions/events/onboarding_sessions)
├── assets/   ├── docs/   └── screens/
```

---

## Architectuur

**App-gate** (`DenHaagApp.swift`): Splash → onboarding-gate → `MainTabView`.
De gate gebruikt **in-memory `@State` `didCompleteOnboarding`** (géén `@AppStorage`):
de onboarding wordt dus bij **élke koude start opnieuw** getoond (bewust, voor demo's),
maar tijdens gebruik blijf je in de app. Terugzetten naar "onthouden" = één regel
(`@AppStorage("didCompleteOnboarding")`).

**Vier tabs** (`MainTabView`, `enum Tab`): `home · regelen · buurt · hulp`.
Tabs staan in een ge-paginade `ZStack`; `BottomTabBar` is een sibling die over alles
heen ligt. Detail-schermen (Parkeren/Afval/Zwemmen/Kwijtschelding/Ooievaarspas) zijn
conditionele overlays met `.move(edge: .trailing)`-transitie, `zIndex(20)`.

### Tab-clipping (let op bij regressies)
Tabs worden **alleen horizontaal** geclipt via `HorizontalClip` (een `Shape` die volledige
breedte neemt maar verticaal ver buiten bounds doorloopt). Reden: `scrollClipDisabled`-
carrousels mochten niet naar andere tabs lekken, maar de gele home-header moet wél achter
de notch doorlopen en de buurt-kaart tot onderaan. **Nooit** een gewone `.clipped()` op de
content-ZStack zetten — dat knipt de notch-gele weg op het toestel.

---

## Schermen — kernpunten

**Onboarding** (`Views/Onboarding/OnboardingView.swift`)
- **7 stappen** (`enum Step`): DigiD-intro → DigiD-login (**inline nagebootst**, ~1,2s
  spinner → Anne) → **naam** ("In de app noemen we je hoe jij dat wil") → Uitleg Regelen →
  Uitleg Buurt → **gemeente-voorkeuren** + **buurt-voorkeuren** (twee losse chip-stappen,
  designs 2866-1251 / 2866-10930).
- Voorkeuren-chips zijn **tekst-only** (`ChoiceChip`) — géén illustraties (die horen alléén
  op de home-tegels). Niets vooraf aangevinkt.
- `finishOnboarding`: mapt **gemeentekeuzes → home-tegel-ids** (`settings.setSelection`),
  bewaart **buurtkeuzes** in `UserDefaults "buurtTopics"`, slaat de **naam** op, en logt alles
  naar **Firestore** (`OnboardingLogService`, collectie `onboarding_sessions`). Elke demo-sessie
  logt opnieuw + vraagt opnieuw om de naam — past bij prototype.

**Home** (`Views/HomeView.swift`, `Views/Components/HeaderView.swift`)
- Gele `HeaderView` (loopt achter de notch) met de **statuskaarten-carrousel**
  (`StatusCardView` + `HomeStatusCard`): twee kaarten met titel, detailregels, **progress-bar**
  en CTA. De balk **loopt vol bij horizontaal scrollen** (`fillProgress`, `.onChange(of:isActive)`)
  met een **pulserend groen puntje** (`PulsingDot`) aan het einde. Kaart 2 heeft een volledig
  groene knop (`buttonFilled`, action `.aanvraag`).
- Greeting dynamisch: **"Hi \(greetingName),"** (naam uit onboarding, fallback "Anne"),
  `theMix 38 extraBold`; subtext "Dit loopt er nu:".
- Eronder: 2-koloms grid van **geselecteerde** `PreferenceTile`s (`TegelView`), elk met
  een **illustratie** (`ill-*`).
- Tap tegel → `MainTabView.handleTile(_:)` routeert naar de juiste overlay/tab
  (incl. `.afspraak` → afspraakscherm; statuskaart-CTA → `.aanvraag` → `AanvraagDetailView`).
- "Startscherm aanpassen" → `CustomizeHomeView` (toggle-lijst van de tegelcatalogus).

**Status-aanvraag** (`Views/AanvraagDetailView.swift`)
- Statuspagina met **progress-bar + pulserend puntje** en een 4-staps tijdlijn; geopend vanaf
  de tweede statuskaart op home (volledig groene knop "Bekijk aanvraag").

**Feedback** (`Views/FeedbackView.swift`)
- **Gestapte flow** (4 schaalvragen + "zou je het gebruiken" + open verbeterpunt; auto-advance
  bij tikken op een score). Schaal-eindpunten gelabeld (bv. 1 = "Zeer onduidelijk", 5 = "Heel
  duidelijk") via `scaleLabel`. **Keyboard-aware**: omdat `MainTabView` `.ignoresSafeArea(.keyboard)`
  doorgeeft, observeert FeedbackView zélf `keyboardWillShow/Hide` zodat de Versturen-knop
  bereikbaar blijft. Geopend vanuit `SettingsView`.

**Regelen** (`Views/RegelenView.swift`)
- `ClaudeService`-chat. Idle-state: gecentreerde kop met **openingsanimatie** (fade + slide).
- Onder de input: `MarqueeTilesView` — tegels schuiven kalm R→L; tap stelt de vraag direct.
- Input-veld + tegels staan bewust wat hoger (bottomInset-tuning, keyboard-aware).

**Buurt** (`Views/Buurt/…`) — zie eigen sectie hieronder.

**Hulp** (`Views/HelpView.swift`)
- Contactopties, "Hulp in de buurt"-carrousel, FAQ-lijst (`HelpFAQView`).

**Passen** (`Views/Components/PassenView.swift`)
- `PasDetailView` toont het **pasje groot** (card-image als hero) + scanbare `BarcodeView`,
  schermhelderheid → 100% tijdens tonen. Ooievaarspas opent via de home-tegel
  (`MainTabView.showOoievaarspas` → `PasDetailView(pas: .ooievaarspas)`).

---

## Buurt-tab — details

- **Kaart**: `BuurtMapView` (`UIViewRepresentable` om `MKMapView`). CARTO Positron
  **no-labels** tile-overlay (`canReplaceMapContent = true`, 512px @2x). Tiles laden via
  **subdomein-rotatie a/b/c/d** (`CartoTileOverlay.url(forTilePath:)`) — één host throttelt
  en liet tegels onvolledig laden. Apple MapKit blijft de basis (privacy-/muted-afweging;
  de minimale Figma-look is bewust niet volledig nagestreefd).
- **Pins**: gele teardrop met categorie-icoon; geselecteerd = groen + 1,5× geschaald.
  Thuislocatie = rustige pulserende **radar** (`RadarPulseView`/`PulseHostView`, CoreAnimation
  buiten de SwiftUI render-loop) — géén mannetje-pin.
- **Carrousel ↔ kaart sync**: één bron van waarheid `selectedItemID`. Tap pin → scrollt
  carrousel + centreert kaart; scroll carrousel → centreert kaart op het centrale kaartje.
- **Actieve-marker-positie**: `itemRegion` gebruikt offset **−0.0015** (lat) met span 0.009,
  zodat de actieve marker nét boven het midden valt (in beeld, boven het kaartje).
  Groter = hoger, kleiner = lager.
- **Camera-overgang**: rustig, lang, ease-out via `UIView.animate(withDuration: 1.1,
  options: [.curveEaseOut, .beginFromCurrentState]) { map.region = region }` — bewust níet
  de korte default `setRegion(animated:)`.
- **Detailpagina** (`BuurtDetailView`): **native iOS 18 zoom-transitie**
  (`NavigationStack` + `.matchedTransitionSource(id:in:)` + `.navigationDestination(item:)`
  + `.navigationTransition(.zoom(sourceID:in:))`, gated met `if #available(iOS 18.0, *)`).
  Bij open detail **verdwijnt de tab bar** (`BuurtView` geeft `detailOpen` door aan
  `MainTabView`, die de `BottomTabBar` weg-offset + fade't).
- **Thuis/werk-dropdown**: wisselt kaartcentrum + home-pin; werkadres in UserDefaults.
- **Onderwerp-filtering** (`BuurtView`): de chips komen uit de **buurtkeuzes uit de onboarding**
  (`UserDefaults "buurtTopics"`, `topicOrder` = evenementen/sport/wegwerk/bouwplannen/participatie).
  `NeighbourhoodItem` heeft `topic` (filter) en optioneel `alternatief` (werkzaamheden-omleiding).
- **Markers rond thuis**: de eerste ~5 items liggen bewust ~150 m rond het thuisadres
  (thuisCoord 52.0705, 4.3007), één per onderwerp, zodat het concept dichtbij toont.
- **Detailpagina** (`BuurtDetailView`): datum-badge **alleen bij evenementen**
  (`item.type == .evenement`); werkzaamheden tonen Periode/Werktijden/Alternatief; "Denk mee"
  toont een **inline poll** (radio-opties) met CTA "Denk mee over dit project".
- **Foto's vs. illustraties** (bewust onderscheid): buurt-kaarten gebruiken **echte foto's**
  (`foto-*` imagesets, jpeg); home-tegels en onboarding gebruiken **illustraties** (`ill-*`).
  Bronbeelden staan in `assets/update/` (13 Gemini-foto's + 2 illustraties) en
  `assets/fotos kantoren/`.

---

## Analytics, feedback & dashboard

- **`Services/AnalyticsService.swift`** (singleton, append-only): `start()` opent een sessie in
  Firestore `sessions/{id}`; `track(event, props)` en `screen(name)` schrijven naar de subcollectie
  `events`; `endSession()` (bij naar achtergrond, `scenePhase == .background`) schrijft een
  eindsamenvatting. `MainTabView` logt tab-switches, scherm-views en overlay-opens; `handleTile`
  logt `tap_tile`. **Géén consent-flow** (bewust, prototype).
- **Firestore-collecties**: `onboarding_sessions` (keuzes), `sessions/{id}` + `events`
  (gedrag). Rules in `firebase/firestore.rules` (sessions create+update, events create-only,
  onboarding create) — deployen via `firebase deploy --only firestore:rules` uit `firebase/`.
- **Dashboard** (`dashboard/`, los Node-project, **niet** de iOS-app): `render.mjs` (puur,
  geen Firebase) → `renderHTML(sessions)` Maze-achtig testverslag (tevredenheid, completion,
  schermen/tegels/tabs/drop-off, onboardingkeuzes, chat-vragen). **Neutraal grijs/wit palet**;
  kleur (`--good`/`--mid`/`--bad`) **alleen** voor goed/slecht-semantiek. `api/index.mjs`
  (firebase-admin, env `FIREBASE_SERVICE_ACCOUNT`) leest Firestore. **Live op Vercel**:
  https://dashboard-tau-pink-91.vercel.app. Lokaal rapport: `node generate.mjs` (script `report`).

---

## Design-conventies

- **Titels** (regelen/buurt/hulp): `AppFont.theMix(size: 26, weight: .bold)` — gelijk gehouden.
- **Body-tekst**: `AppFont.theSans`. Detail-titels groter (`theMix 30`).
- **Kleuren** via `AppColors` (o.a. `groen3 #248641`, `geel3`, `grijs2`, `textPrimary`,
  `textSecondary`). Tokens in `Models/AppTheme.swift`.
- **`AppDesign.safeAreaTop`** — gedeelde helper voor de device safe-area top (notch);
  niet opnieuw via `connectedScenes` dupliceren.
- **`AppDesign.horizontalPadding`** / **`cornerRadius`** — standaard spacing.
- **Back-knop**: `BackCircleButton` (chevron, 90% wit, 1px `grijs2`-border).
- Detail-schermen: paginatitel **mee-scrollend** (geen sticky title), back-knop bovenin.
- Commentaar en UI-teksten in het **Nederlands**.

---

## Build & Deploy

**Toestel**: iPhone 15 "**Fappiefoon**" — device-id `D86F08DE-A6F8-5727-AB6C-C151C89B5149`.
Verschijnt soms als `unavailable` wanneer vergrendeld of kabel los → ontgrendelen/aansluiten.

**Build + install op toestel (kabel):**
```bash
cd "DenHaag"
xcodebuild -project DenHaag.xcodeproj -scheme DenHaag -configuration Debug \
  -destination 'platform=iOS,name=Fappiefoon' -allowProvisioningUpdates \
  -derivedDataPath build/device build
xcrun devicectl device install app --device D86F08DE-A6F8-5727-AB6C-C151C89B5149 \
  "build/device/Build/Products/Debug-iphoneos/Den Haag.app"
```
Launch lukt niet als het toestel op slot staat (install wél) — gebruiker opent zelf.

**Compile-check / visuele verificatie zonder toestel**: simulator (`platform=iOS Simulator,
name=iPhone 17 Pro`), `xcrun simctl install/launch booted` + `simctl io booted screenshot`.

**TestFlight**: pas wanneer alles goed is. Headless recept (build bumpen → archive → export
→ `altool` met API-key Key ID/Issuer ID) staat in de memory-notitie *testflight-deploy*.

**Versie**: `project.yml` → `MARKETING_VERSION 1.0.0`, `CURRENT_PROJECT_VERSION` (bumpen bij
TestFlight). `ITSAppUsesNonExemptEncryption: false`.

---

## Belangrijke regels & valkuilen

- **Start NOOIT een lokale dev server** — dit is een native iOS-app, geen web app.
- **Na het toevoegen van een nieuw Swift-bestand**: `xcodegen generate` draaien, anders
  "cannot find … in scope". `project.yml` genereert ook de Info.plist (`info.properties`).
- **Niet** het `.xcodeproj` handmatig editen — het wordt geregenereerd.
- **Werkproces** (staande afspraak): éérst het probleem + testcriteria bepalen, dán bouwen,
  dán checken, en bij gebreke de loop herhalen. Verifieer op het toestel (of sim) met
  screenshots vóór je iets "klaar" noemt.
- **TestFlight** pas op expliciet sein "alles is goed".
- Gebruik **Figma MCP** voor exacte design-specs (file `L55Hzh3QOCKsK4t5elCRcA`).
- Communiceer in het **Nederlands**.

---

## Gerelateerde memory-notities

- `buurt-kaartstijl` — kaartstijl-afweging (Apple MapKit muted vs. externe tiles/privacy)
- `testflight-deploy` — headless upload-recept + API-key
- `firestore-onboarding-logging` — onboarding-keuzes → Firestore (`denhaag-app-fappie`)
