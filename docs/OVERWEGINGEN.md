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
