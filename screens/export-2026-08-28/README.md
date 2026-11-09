# Schermen-export DH-app — 28 augustus 2026

Gemaakt in de iPhone 17 Pro-simulator (iOS 26.5), Debug-build van `DenHaag.xcodeproj`,
bundle `nl.denhaag.app`. 1206×2622 px (3×).

## Wat er in zit
- **01–11** Splash + onboarding (DigiD, gegevens ophalen, naam leeg/ingevuld,
  twee uitlegschermen, taken-chips leeg/gekozen, buurtvoorkeuren leeg/gekozen)
- **12–16** Home: alle vier de statuskaarten in de carrousel + onderkant met tegels
- **17–18** Startscherm aanpassen (boven + onder)
- **19–23** Profiel/instellingen, taalkeuze, Turks gekozen, instellingen én home in het Turks
- **24–30** Uitgangspunten (alle 7 kaarten)
- **31–36** Feedback-flow (4 cijfervragen, cijfer-gekozen-state, ja/misschien/nee, vrije tekst)
  — bewust *niet* verstuurd
- **37–41** Regelen: leeg, vraag getypt, laden, foutmelding, tegels
- **42–47** Buurt: alle filterstates (alles, evenementen, sport, werk aan de weg,
  bouwplannen, participatie)
- **48–50** Buurtdetail incl. peiling leeg en gestemd
- **51–54** Locatiekeuze thuis/werk, werkadres instellen, "Rondom werk"
- **55–56b** Hulp-tab boven en onder

## Wat er níet in zit
- Detailschermen achter de home-tegels (parkeren, afval, afvalkalender, zwemmen,
  ooievaarspas, kwijtschelding + uitlegvideo, aanvraag, paspoort, afspraak,
  evenement, bieb/rechten, grofvuil)
- FAQ-schermen in Hulp — die openen niet (zie hieronder)

## Opgemerkt tijdens het maken
1. **Hulp → Veelgestelde vragen doet niets.** Tikken op Parkeren/Wonen/Geldzaken
   opent `HelpFAQView` niet. Het scherm is dus onbereikbaar.
2. **AI-chat in Regelen faalt** ("Er ging iets mis"). `ClaudeService` gebruikt
   model `claude-sonnet-4-20250514`; sleutel of model is verlopen.
3. **Kaart toont "API KEY REQUIRED"** — de CARTO-tiles hebben geen geldige sleutel.
4. **Toggles reageren niet op een kale tik** in de simulator; alleen op een sleep.
   Op een echt toestel waarschijnlijk geen probleem, maar het is wel een smalle marge.
