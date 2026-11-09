# DH App — Testverslag-dashboard

Genereert uit de Firestore-analytics van de DH App een zelf-bevattend HTML-testverslag
(`dashboard.html`): per sessie de scores, de onboarding-keuzes en een volledige tijdlijn
van wat er getikt en getypt is (inclusief de chat). Eén bestand dat je in je browser
opent of deelt.

## Eenmalige setup

1. **Service-account-key downloaden** (read-only toegang tot Firestore):
   Firebase Console → project `denhaag-app-fappie` → ⚙️ Projectinstellingen →
   tab **Service-accounts** → **Nieuwe private key genereren**.
   Sla het JSON-bestand op in deze map als:

   ```
   dashboard/serviceAccount.json
   ```

   (Staat in `.gitignore` — niet committen, het geeft volledige projecttoegang.)

2. **Dependencies installeren** (eenmalig):

   ```bash
   cd dashboard
   npm install
   ```

## Dashboard genereren (lokaal, statisch)

```bash
npm run report
```

Dit haalt alle sessies + events op en schrijft `dashboard.html`. Open dat bestand
in je browser. Draai het commando opnieuw wanneer je verse data wilt.

## Live op Vercel

Het dashboard staat live: **https://dashboard-tau-pink-91.vercel.app**
(een serverless functie die bij elk bezoek live uit Firestore leest).

Om de data te tonen moet de service-account éénmalig als env-var:

```bash
# vanuit de dashboard-map, met serviceAccount.json aanwezig:
vercel env add FIREBASE_SERVICE_ACCOUNT production < serviceAccount.json
vercel --prod
```

Of via de Vercel-website: project `dashboard` → Settings → Environment Variables →
`FIREBASE_SERVICE_ACCOUNT` = de volledige inhoud van het JSON-bestand → Redeploy.
Zonder die variabele toont de site een korte uitlegpagina.

## Wat zie je

- **Bovenaan**: aantal sessies, hoeveel met feedback, gemiddelde sessieduur, totaal events.
- **Gemiddelde scores**: de vier feedback-vragen (1–5) over alle sessies, plus de
  "zou je de app gebruiken?"-verdeling.
- **Per sessie** (klik om uit te klappen): naam, gekozen taken/buurt-onderwerpen,
  de ingevulde feedback, en een tijdlijn van elke gebeurtenis met de tijd-sinds-start
  (chatberichten worden als bubbels getoond).

## Bestanden

- `generate.mjs` — haalt data uit Firestore en schrijft `dashboard.html`.
- `render.mjs` — pure HTML-rendering (geen Firebase).
- `selftest.mjs` — rendert met verzonnen data om de opmaak te checken: `node selftest.mjs`.
