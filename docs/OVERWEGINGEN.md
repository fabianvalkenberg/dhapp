# Overwegingen — DH App

Append-only. Gesprekken en afwegingen die (nog) geen besluit werden: de vraag,
wat we zagen, de opties en wat er openstaat. Wordt iets een besluit, dan staat
de conclusie in `DECISIONS.md` met een verwijzing hierheen.

## 2026-11-03 · Knop op het controlescherm van de meldflow: "Volgende" of "Verstuur"

Figma zegt "Volgende". Maar het is de knop die de melding echt verstuurt, en
het huidige MOR-prototype zegt daar "Verstuur".

- **Volgende (nu):** gelijk aan Figma. Risico: iemand denkt dat er nog een
  stap komt en schrikt dat de melding al weg is.
- **Verstuur:** zegt wat er gebeurt. Wijkt af van Figma.

**Advies:** Verstuur.

**Afgesloten 2026-11-07 (beslisbak):** blijft "Volgende", gelijk aan Figma.
Zie DECISIONS.md.

## 2026-11-03 · Overzicht "Uw meldingen" als begin van de meldflow

Het huidige MOR-prototype heeft een overzicht met je eigen meldingen en hun
status, meldingen in de buurt op een kaart, en een knop "Nieuwe melding". Dat
staat niet in Figma MOR '26. Gepland en daarna niet gebouwd.

**Afgesloten 2026-11-07 (beslisbak):** niet bouwen. Zie DECISIONS.md.

## 2026-11-03 · Tegelillustraties: wat ontbreekt

Overzicht in `screens/tegel-illustraties.png`, gemaakt met het script dat de
echte assets gebruikt. Stand: 18 tegels met een eigen illustratie, 9 die er een
lenen van een andere tegel, 3 met alleen een icoon (Naar de bieb, Mijn
vergunningen, Terras of uitstalling). Er staan drie illustraties in de app die
nergens gebruikt worden: `ill-kliko`, `ill-parkeren`, `ill-passen`.

**Afgesloten 2026-11-07 (beslisbak):** de drie tegels houden hun icoon; er
worden geen illustraties aangeleverd. Zie DECISIONS.md.

## 2026-11-03 · Intervisie: wat er met "profiel in test is geel" bedoeld werd

Het transcript zei dat de profielachtergrond in de testversie geel is "zoals in
de header", en blauw wordt bij Kapsalon Anne. Gelezen als: de homekop moet
hetzelfde doen als het profiel (blauw bij de ondernemer). Het profiel zelf is
groen gebleven. **Open:** klopt die lezing?

## 2026-11-04 · Kleine dingen die zijn gezien maar niet aangepast

- Regelen begroet de ondernemer met "Hi Anne" in plaats van Kapsalon Anne.
- In de chat schuift je eigen vraag bij scrollen onder de statusbalk door.
- De testversie vraagt bij élke start je naam, ook als je die al gaf. Voor
  testsessies met steeds een nieuwe deelnemer is dat misschien juist goed.
- De meldflow en de chat gebruiken "u", de rest van de app "je" (zie VOICE.md).

## 2026-11-10 · Fietsendesign: wat we bewust níet overnamen

- **Lijst-sheet onderin de kaart** (flow 01 scherm 3) tegenover de knoppen "5 in
  de buurt" + "Lijst" uit de review van 9 november. Fabian koos de knoppen: één
  patroon in heel Buurt. Het aparte sheet-concept stond in Figma al op "KILL
  your darlings". Open: als testers de lijst niet vinden, komt de sheet terug.
- **Nieuw stallingskaartje met kruisje** (flow 01 scherm 4): Fabian hield het
  oude kaartje. "Past bij je bakfiets" staat daardoor alleen op de
  stallingspagina, niet op het kaartje.
- **Voordrager:** geen enkele bron (Biesieklette, denhaag.com) noemt het. De
  filteroptie staat er daarom niet; navragen bij Biesieklette zou hem terugbrengen.
- **Chiphoogte:** de review gebruikt 43 pt, het fietsendesign 36 pt. We hielden
  43 voor heel Buurt; de designers moeten kiezen.
- **Werkwijze bij krappe credits:** code laten schrijven door DeepSeek via
  OpenModel (Otto), Claude controleert, bouwt en test. Werkte voor flow 03 in
  één keer; het controleren kost nog steeds de meeste Claude-tokens (screenshots).

## 2026-11-10 · Naamscherm en filtericoon in Versie 2: de opties die het niet werden

**Naamscherm.** Een collega meldde na build 31 dat Versie 2 het naamscherm
oversloeg (het werd maar één keer per toestel getoond). Twee opties:
1. Bij elke start, zoals "Prototype testen". Gekozen: bij testen met steeds een
   nieuwe deelnemer moet iedereen bij zijn eigen naam beginnen.
2. Eén keer per toestel, en opnieuw als je Versie 2 kiest bij "Versie van de
   app". Zo kan een tester het zelf resetten, maar je moet het wel weten.
Open: vragen we de naam ook opnieuw als de app uit de achtergrond terugkomt?
Nu niet; alleen bij echt opnieuw opstarten.

**Filtericoon op de buurtkaart.** De Fix-kaart zei "het filtericoon links
blijft staan". Het icoon filtert alleen stallingen, dus het staat er bij
"Fiets stallen" en niet bij "Alles", zoals in de testversie. Open: als de
designer het icoon altijd zichtbaar wil, moet eerst duidelijk zijn wat het bij
"Alles" doet.

