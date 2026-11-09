# Samenwerken aan de DH App

Voor iedereen die meebouwt. GitHub is de waarheid:
https://github.com/fabianvalkenberg/dhapp

## Eenmalig opzetten

1. Installeer Xcode (App Store) en open het één keer, zodat de iOS-simulator
   wordt geïnstalleerd.
2. Installeer XcodeGen: `brew install xcodegen`.
3. Clone de repo naar een map **buiten Dropbox, iCloud of OneDrive**:
   `git clone https://github.com/fabianvalkenberg/dhapp.git`
4. Open die map in de Claude-app (Code-tab). Claude leest `CLAUDE.md` en kent
   daarmee de regels van het project.
5. Vraag Claude om de app in de simulator te bouwen en te starten. Lukt dat,
   dan staat alles goed.

## Per wijziging

1. **Begin bij de laatste stand.** Start een nieuwe sessie; Claude maakt een
   eigen branch vanaf `main`.
2. **Eén wijziging per branch.** Een scherm, een flow, een fix. Klein houden:
   kleine wijzigingen botsen minder en zijn sneller beoordeeld.
3. **Bewijs in de simulator.** Niets is klaar zonder screenshot van het scherm
   én van de route ernaartoe.
4. **Open een pull request** naar `main`, met de screenshots erin en één zin
   over wat er veranderd is en waarom.
5. **Fabian beoordeelt en merget.** Niemand pusht rechtstreeks naar `main`.

## Afspraken die botsingen voorkomen

- **Meld waar je aan werkt** voordat je begint. Twee mensen in hetzelfde scherm
  levert altijd conflicten op.
- **`LanguageManager.swift` is de botsplek.** Elke nieuwe tekst raakt daar drie
  dictionaries. Voeg sleutels toe bij het blok van jouw scherm, niet onderaan,
  en haal `main` binnen vlak voordat je je pull request opent.
- **`MainTabView.swift` en `HomeView.swift` raak je alleen aan als het moet.**
  Daar komt alles samen.
- **Het `.xcodeproj` staat niet in de repo.** Het wordt gegenereerd uit
  `project.yml`. Na een pull of na een nieuw Swift-bestand: `xcodegen generate`
  in `DenHaag/`.
- **Besluiten en toon leg je vast.** Een keuze die een ander moet kennen gaat in
  `docs/DECISIONS.md`, nieuwe terminologie in `docs/VOICE.md`. Wat alleen in
  jouw Claude-geheugen staat, bestaat voor de rest niet.

## Wat alleen via Fabian loopt

- Bouwen op een iPhone en uploaden naar TestFlight (signing staat op zijn
  Apple-team).
- Firestore-rules en het dashboard deployen.
- Mergen naar `main`.

Wil je de app op je eigen telefoon zien: vraag Fabian om je als tester aan
TestFlight toe te voegen.
