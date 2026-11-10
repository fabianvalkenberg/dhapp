# DH-app prototype — zwemmen en parkeren

Klikbaar prototype van de mini-apps **Zwemmen** (met zwemles) en **Bezoekersparkeren** binnen de Den Haag app.
Gebouwd als één zelfstandig HTML-bestand. Live versie: https://claude.ai/artifact/CTbyE3H1UsWsRvXaj6eGrF

## Openen

Open `index.html` in een browser. Er is geen server, build of installatie nodig.
Alleen de QR-code-bibliotheek wordt van internet geladen (cdnjs, `qrcode-generator` 1.4.4).

Op een breed scherm staat de app in een telefoonframe; smaller dan 600 px vult hij het scherm.

## Belangrijk om te weten

- **Dit is een prototype, geen productiecode.** Er zijn geen API-koppelingen. Alle gegevens zitten in het bestand of worden in `localStorage` van de browser bewaard.
- **Gebruik het als functionele en visuele referentie**, niet als code om één-op-één over te nemen in een native app. Schermen, teksten, toestanden en regels (zie hieronder) zijn wel direct bruikbaar als specificatie.
- **Lettertypen:** TheSans C4s en TheMixB zitten als base64 in het bestand. Controleer de licentie voordat je ze in een app meelevert.
- **Foto's van de zwembaden** komen van denhaag.nl en zitten als base64 in het bestand.

## Opbouw van `index.html`

| Regels (ongeveer) | Onderdeel |
|---|---|
| begin | CSS van de app-omgeving (telefoon, statusbalk, lagen, parkeren, instellingen) |
| `window.DHSwim = (function(){` | **Mini-app Zwemmen**, inclusief zwemles. Draait in een eigen shadow root, zodat de stijlen elkaar niet raken. Bevat eigen CSS, data, schermen en klikacties. |
| `const ZONES = [` e.v. | **Bezoekersparkeren**: zones en betaaltijden (RDW Open Data), scenario's, schermen |
| `VIEWS.settings` | Instellingen achter het tandwiel: tijd, scenario's parkeren, zwemmen en zwemles |
| einde | Navigatie (lagen), lockscreen met Live Activity, klok |

### Mini-app Zwemmen (`DHSwim`)

- **Schermen** (`RENDER`): `home`, `kopen` (activiteitenoverzicht), `detail` (activiteit), `pool` (zwembad), `tickets` (Mijn kaartjes), `les` (zwemles), `wacht` (wachttijden), `aanmeld` (kind aanmelden, 3 stappen), `kid` (kind: wachtlijst of op les), `voortgang`, `abo` (abonnement).
- **Data**:
  - `WEEK`: weekrooster per weekdag, uit de kalender van denhaag.nl (gewone schoolweek 26 okt – 1 nov 2026).
  - `POOLINFO`: adres, telefoon, foto en voorzieningen per zwembad.
  - `priceSection()`: prijzen 2026 van de pagina Kosten zwemactiviteiten.
  - `WACHT`: wachttijden zwemles per zwembad (indicatie uit de sportwebshop).
  - `lesKids()`: voorbeeldkinderen voor zwemles (Noor op les, Sem op de wachtlijst).
- **Regels die het gedrag bepalen**:
  - `freeBadge()`: status op de zwembadkaart (activiteit die nu bezig is, anders de eerstvolgende, anders de eerstvolgende dag).
  - `freeSection()`: blok “Nu en straks” op de zwembadpagina (max. 2 activiteiten).
  - `cat()` / `match()`: activiteitgroepen en filters (zwembad, activiteit, dagdeel).
  - `scrollToNow()`: activiteitenoverzicht scrolt bij openen naar de eerste activiteit die niet afgelopen is.
- **Tijd**: alles rekent met `API.now()`, die de app-omgeving zet. Zo werkt de tijdinstelling in het tandwiel ook voor zwemmen.
- **Koppeling met de app-omgeving** via `DHSwim.open()`, `.set()`, `.state()`, `.reset()`, `.exit`, `.changed`, `.light`, `.now`.

## Wat nep is

- Betalen (inschrijfgeld, abonnement, kaartjes) toont geen betaalstap.
- QR-codes zijn echte, scanbare codes met voorbeeldinhoud.
- Plek op de wachtlijst en verwachte oproep bij een nieuwe aanmelding zijn een schatting.
- Oefeningen in het leerlingvolgsysteem zijn voorbeelden, niet de officiële Zwem-ABC-lijst.
- “Zo werkt zwemles”, “Kosten”, “Is je situatie veranderd?”, “Lees meer”, “Voorkeuren” en “Route” doen nog niets.
