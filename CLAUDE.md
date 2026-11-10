# CLAUDE.md — DH App

Prototype van een gemeente-app voor Den Haag. **Native iOS/SwiftUI**, Xcode.
Dummy-data, nagebootste DigiD. Communiceer in het **Nederlands**.

Meer context: `docs/product.md` · besluiten en waaroms: `docs/DECISIONS.md` ·
UI-teksten en toon: `docs/VOICE.md` · afwegingen zonder besluit:
`docs/OVERWEGINGEN.md`.

---

## Stand van zaken

- **Stack:** SwiftUI (iOS 17+), XcodeGen (`project.yml` genereert het
  `.xcodeproj`), MapKit + CARTO-tiles, Firebase/Firestore
  (project `denhaag-app-fappie`).
- **Repo:** https://github.com/fabianvalkenberg/dhapp. Meerdere designers
  bouwen mee: één wijziging per branch, pull request naar `main`, Fabian
  merget. Nooit rechtstreeks naar `main` pushen. Werkwijze:
  `docs/SAMENWERKEN.md`.
- **Toestel:** iPhone 15 "Fappiefoon", device-id
  `D86F08DE-A6F8-5727-AB6C-C151C89B5149`. Verschijnt als `unavailable` bij
  vergrendeling of losse kabel.
- **Dashboard:** los Node-project in `dashboard/`, live op
  https://dashboard-tau-pink-91.vercel.app
- **Structuur:** `DenHaag/DenHaag/` met `Models/`, `Services/`, `Views/`
  (+ `Views/Components/`, `Views/Buurt/`, `Views/Onboarding/`, `Views/Melding/`,
  `Views/Fiets/`).
- **Versies:** V1 · V2 · V3 · Prototype testen. Wat een versie toont (onderdelen,
  tabs, vaste tegels) staat alleen in `Models/AppVersie.swift`.
- **Rollen:** inwoner of ondernemer ("Kapsalon Anne", Hoefkade 12) via
  `RolManager`; wisselen door te vegen in de profielkop.
- **Chat (Regelen):** `Services/ClaudeService.swift`, model `claude-sonnet-5-5`.
- **Laatste TestFlight-build:** 32 (zie memory *testflight-deploy*). Sinds
  2026-11-10 zijn PR #1 t/m #15 samengevoegd: `origin/main` is gelijk aan build 32.
  Volgende build bouw je vanaf `origin/main`.

## Bouwen

⚠️ `xcode-select` wijst op deze Mac naar CommandLineTools: zet eerst
`export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, anders faalt
`xcodebuild`.

⚠️ Bouwen in een eigen git-worktree: kopieer eerst het ge-gitignorede
`DenHaag/DenHaag/Services/APIConfig.swift` uit de hoofdmap en draai
`xcodegen generate`, anders faalt de build op "cannot find 'APIConfig'".

⚠️ Een cloud-sessie heeft geen Xcode: daar kun je code schrijven, maar niet
bouwen, in de simulator testen of naar TestFlight uploaden. Dat kan alleen op
deze Mac.

Simulator (compile-check en visuele verificatie, iPhone 17 Pro
`35221942-7918-4D44-8811-0C7CCE1508BD`, bundle `nl.denhaag.app`):

```bash
cd DenHaag && xcodebuild -project DenHaag.xcodeproj -scheme DenHaag \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build/sim build
```

Toestel via kabel: zelfde commando met
`-destination 'platform=iOS,name=Fappiefoon' -allowProvisioningUpdates
-derivedDataPath build/device`, daarna `xcrun devicectl device install app`.
Launchen lukt niet als het toestel op slot staat (installeren wél).

Testharnas (alleen DEBUG), als launch-argumenten bij `xcrun simctl launch`:
`-versie v1|v2|v3|test` · `-rol inwoner|ondernemer` · `-geennaam` ·
`-tab buurt|regelen|hulp` · `-scherm <naam>` (zie DECISIONS) · `-melding` · `-meldstap <intro|wat|waar|foto|onveilig|vervolg|contact|controle|klaar>`
· `-meldcat <verlichting|auto|container|grofvuil|anders>` · `-fietspas` · `-zwemmen`
· `-buurtfilter <onderwerp>` (bijv. `fietsparkeren`). Testcodes voor de
foutschermen van "pas toevoegen" staan in DECISIONS.md (2026-11-10).

## Regels

**Proces**
- ⚠️ Eerst het probleem en de testcriteria bepalen, dán bouwen, dán checken.
  Bij gebreken: loop herhalen.
- ⚠️ Niets heet "klaar" zonder screenshot-bewijs uit de simulator of van het
  toestel. Een geslaagde build is geen bewijs dat een scherm bereikbaar is.
- ⚠️ TestFlight alleen op expliciet sein "alles is goed". Recept staat in de
  memory-notitie *testflight-deploy*.
- Gebruik de Figma MCP voor exacte design-specs (file `L55Hzh3QOCKsK4t5elCRcA`;
  meldflow: `HfvOJp3cD2kSUXPf8Yx3TA`, node 1104-5637). Designers zetten
  bugs als "Fix"-frame met instructiekaart in "DH App | Design file"
  (`wvwF4ED2uW2omIH8vYvDSx`); de kaart is de spec, inclusief "niet aanpassen".
- ⚠️ Gestapelde PR's samenvoegen met merge-commits (geen squash), in
  stapelvolgorde, telkens eerst de volgende PR op `main` richten. Conflicten in
  DECISIONS.md zijn meestal twee nieuwe besluiten onderaan: houd beide.
- ⚠️ Vergelijk met Figma op ware puntgrootte: Figma-screenshot op 1x naast de
  simulator-screenshot gedeeld door 3. Nooit schalen naar 393 breed — dan
  verschuift alles en meet je niets.
- ⚠️ Screenshot-bewijs via `xcrun simctl io <device-id> screenshot`. De
  screenshot van de simulator-tool kan een oud beeld tonen; geef die tool altijd
  het device-id mee, anders stuurt hij een ander toestel aan.
- Feiten over plekken (adressen, coördinaten, fietstypen, voorzieningen) worden
  opgezocht, niet geschat. Onbekend blijft onbekend en telt niet mee in een filter.
- ⚠️ Werken meerdere sessies tegelijk aan deze repo: elke sessie een eigen
  git-worktree én een eigen simulator. Nooit van branch wisselen in een map of
  simulator die een andere sessie gebruikt.

**Project en build**
- ⚠️ Start nooit een lokale dev server — dit is een native iOS-app, geen web-app.
- ⚠️ Na het toevoegen van een nieuw Swift-bestand: `xcodegen generate` draaien,
  anders "cannot find … in scope".
- ⚠️ Het `.xcodeproj` nooit handmatig editen; het wordt geregenereerd.
  `project.yml` is de bron van waarheid (ook voor Info.plist en versienummers).
- Nieuwe bundle-resources gaan in `project.yml` zonder `type: folder`, zodat
  `Bundle.main.url(forResource:withExtension:)` ze plat terugvindt.

**Code en UI**
- ⚠️ Nooit een gewone `.clipped()` op de content-ZStack in `MainTabView` —
  dat knipt de gele notch-header weg op het toestel. Tabs worden alleen
  horizontaal geclipt via `HorizontalClip`.
- ⚠️ Elke nieuwe UI-tekst krijgt een sleutel in **alle drie** de dictionaries
  van `LanguageManager` (nl/en/tr).
- ⚠️ Een nieuw detailscherm is pas af als er een route naartoe is die je in de
  simulator kunt aflopen. Controleer dat de callback ook echt wordt aangeroepen —
  een ongebruikte callback is geen compilerfout.
- Gebruik `AppDesign.safeAreaTop` voor de notch; niet opnieuw via
  `connectedScenes` uitrekenen.
- Kleuren en fonts via `AppColors` / `AppFont` (`Models/AppTheme.swift`);
  spacing via `AppDesign.horizontalPadding` / `cornerRadius`.
- Detail-schermen: paginatitel scrollt mee, back-knop via `BackCircleButton(stijl:)`
  + `.terugknopPlek()`; nooit een eigen terugknop bouwen. Scrollende schermen
  krijgen `.bovenVervaging()` op hun ScrollView.
- Home-tegels en onboarding gebruiken illustraties (`ill-*`); buurt-kaarten
  gebruiken echte foto's (`foto-*`). Voorkeuren-chips in de onboarding zijn
  tekst-only.
- Commentaar en UI-teksten in het Nederlands.
- ⚠️ `MainTabView` geeft `.ignoresSafeArea(.keyboard)` door. Een scherm met
  invoervelden moet dus zélf `keyboardWillShow/Hide` observeren, anders
  verdwijnt de verstuurknop achter het toetsenbord (zie `FeedbackView`).
- De buurt-kaart centreert met offset −0.0015 lat en span 0.009, zodat de
  actieve marker net boven het midden valt. Groter = hoger. Bij vaste plekken
  staan jij én de dichtstbijzijnde plek in beeld (`BuurtView.regioMet`).
- ⚠️ De radar om je locatie ligt onder de markers (`zPriority = .min`); de stip
  zelf is een aparte `StipAnnotation` erboven. De radar en
  `PulseHostView` herstart zijn animatie bij `didMoveToWindow` en bij terugkomst
  uit de achtergrond. Haal dat niet weg: CoreAnimation gooit animaties dan weg.
- ⚠️ Een nieuwe home-tegel of statuskaart hoort bij een onderdeel in
  `AppVersie`; een versie toont nooit iets van een onderdeel dat hij niet heeft.
- Als ondernemer: homekop blauw met witte tekst, knoppen op de kaarten blijven
  groen, kaartranden `blauw1`.
- Meldflow: vervolgvragen staan één per scherm; een vraag die alleen bij een
  bepaald antwoord hoort, krijgt `alleenBij`. Afwijkingen van Figma staan in
  DECISIONS.md.
- ⚠️ Na een modelwissel in `ClaudeService`: test of het antwoord in de app
  verschijnt, niet alleen of de API 200 geeft. Pak altijd het eerste blok met
  `type == "text"` — het model kan eerst een denkblok sturen.

**Analytics en dashboard**
- Firestore-rules deployen: `firebase deploy --only firestore:rules` vanuit
  `firebase/`.
- ⚠️ In het dashboard (`dashboard/`) is het palet neutraal grijs/wit. Kleur
  (`--good`/`--mid`/`--bad`) uitsluitend voor goed/slecht-semantiek, nooit
  decoratief. `render.mjs` blijft puur — geen Firebase-aanroepen daarin.

**Getallen richting inwoners**
- ⚠️ Feiten over regelingen komen van denhaag.nl, niet uit een schatting of een
  samenvatting van derden. Kwijtschelding: ontvangstbevestiging binnen 10 dagen,
  besluit binnen 13 weken, bezwaar binnen 10 dagen.

## Uitlegvideo's

Korte portrait-video's die een onderwerp uitleggen, nu bij kwijtschelding.

- Catalogus: `Services/VideoLibrary.swift`. Bestanden in
  `DenHaag/Resources/Video/` (`NL-01/02/03.mp4`, `turks-01.mp4`).
- Instapkaart: `Views/Components/ExplainerCardView.swift`, staat ín het
  onderwerpscherm — nooit in een aparte videosectie.
- Speler: `Views/Components/ExplainerPlayerView.swift`. Schermvullend, met aan
  het eind altijd een keuze (volgende deel · sluiten).
- ⚠️ De taalknop hoort in de speler, niet in de app-instellingen. Wie uitleg in
  eigen taal nodig heeft, heeft de app-taal meestal niet omgezet.
- Video's per taal zijn losse opnames met een eigen script, geen vertaling.

## Open werk

- [ ] ⚠️ De oude **lokale** branches `main` en `werk-2026-11-07` bevatten een
      API-sleutel in de geschiedenis en lopen niet gelijk met `origin/main`:
      **nooit pushen**, en nieuw werk altijd vanaf `origin/main` beginnen.
      Opruimen kan, maar alleen met Fabians akkoord.
- [ ] Nog open uit design review en fietsendesign: tegels zelf ordenen en
      aanpassen op het startscherm ("geen prio"); fietsen-flows 04 (hoe lang
      staat mijn fiets) en 05 (pas blokkeren); Apple Wallet echt koppelen;
      scherp Dappre-icoon aanleveren (`fp-dappre` is een 1x-export).
- [ ] Lokale restanten: branch `fietsen-02-pas-toevoegen` (oude WIP, vervangen
      door `fietsen-02-passen-toevoegen`), de bouwbranches `testflight-30/31/32`
      (zitten al in `main`), twee git-worktrees in `/private/tmp/claude-501/…`
      en de extra simulators "iPhone 17 Pro Fietsen" en "… Buurtfilters".
      Opruimen kan, maar alleen met Fabians akkoord.
- [ ] Microfoon en fotokiezer in de meldflow zijn niet getest (kan niet in de
      simulator). Op het toestel nalopen.

- [ ] **"Opnieuw kijken" is verwijderd uit de speler** omdat de knop het scherm
      sloot in plaats van te herstarten. Oorzaak niet gevonden: het lag niet aan
      `start()`, niet aan de Binding van de cover en niet aan AVKit's
      `VideoPlayer` — alle drie apart uitgesloten. Voor terugzetten is eerst een
      diagnose nodig, geen vierde gok.
- [ ] Turkse video-tekst is niet gecontroleerd door een moedertaalspreker.
      Niet buiten interne demo's gebruiken tot dat gebeurd is.
- [ ] De video's hebben een Synthesia-watermerk (gratis account). Bij een
      vertrouwenstest beïnvloedt een vreemd bedrijfslogo precies wat je meet.
- [ ] Geen "gemaakt met AI"-label in beeld. Openstaande vraag: merken mensen het,
      en stoort het ze?
- [ ] Turkse delen 2 en 3 bestaan nog niet.
- [ ] Video's staan alleen bij kwijtschelding. Andere kandidaten met veel jargon:
      bezwaar maken, Ooievaarspas.
