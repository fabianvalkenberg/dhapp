# Toon en terminologie — DH App

Alles wat de inwoner leest. Voor code-commentaar geldt hetzelfde principe
(Nederlands), maar dit document gaat over UI-teksten.

## Uitgangspunt

Taalniveau **B1**, volgens de Direct Duidelijk-schrijfregels van de overheid.
De lezer begrijpt de tekst in één keer, zonder tweede lezing.

- Hoofdboodschap bovenaan. Val met de deur in huis.
- Zinnen van ongeveer 10-12 woorden. Wissel lengte af.
- Actief en persoonlijk. Geen lijdende vorm.
- Positief formuleren: "Geef je op tijd op", niet "Geef je niet te laat op".
- Geen beeldspraak, geen afkortingen, geen Engels.

## Aanspreekvorm

De app gebruikt consequent **je/jij**, niet u.

> "Je aanvraag voor kwijtschelding is ontvangen."
> "In de app noemen we je hoe jij dat wil."

Dit wijkt af van de overheidsstandaard (die "u" voorschrijft). Als dat ooit
omgaat, is het een find-replace door `LanguageManager` — maar dan wél overal
tegelijk, inclusief de video-scripts.

**Bekende afwijking (open):** de meldflow volgt Figma MOR '26 en zegt "u"
("Waar gaat uw melding over?"), en de chat in Regelen antwoordt met "u" omdat
de systeemprompt dat vraagt. De rest van de app zegt "je". Kies één vorm voordat
dit naar inwoners gaat; zie `docs/OVERWEGINGEN.md`.

## Drie talen, altijd samen

Elke nieuwe UI-tekst krijgt een sleutel in **alle drie** de dictionaries van
`LanguageManager`: `nl`, `en`, `tr`. Een sleutel die maar in één taal bestaat,
valt in de andere talen terug op de sleutelnaam zelf — dat is zichtbaar lelijk.

Turks gebruikt de beleefdheidsvorm (`-nuz`), ook waar het Nederlands je/jij
gebruikt.

## Terminologie

| Gebruik | Niet |
|---|---|
| kwijtschelding | belastingvrijstelling, ontheffing |
| aanvraag | verzoek, applicatie |
| in behandeling | in procedure, wordt verwerkt |
| je hoeft niet te betalen | vrijstelling van betaling |
| bezwaar maken | in beroep gaan |
| uitstel van betaling | betalingsregeling |
| buurt | wijk, gebied |
| regelen | diensten, producten |
| melden | rapporteren |
| je zaak (ondernemer) | je bedrijf, je onderneming |
| Voor je zaak (buurtfilter) | Ondernemers, Zakelijk |
| Zet morgen je oud papier buiten | Ophaaldag papier: morgen |

**Let op het verschil melding / aanvraag.** De Ombudsman stelde vast dat
inwoners dat verschil niet begrijpen. Gebruik de woorden dus nooit door elkaar,
en leg uit wat er gebeurt in plaats van het onderscheid te benoemen.

## Knoppen

Werkwoord + object, geen losse werkwoorden.

> "Bekijk aanvraag" · "Neem contact op" · "Volgende video" · "Opnieuw kijken"

Niet: "Verder", "OK", "Klik hier".

## Video-scripts

Gesproken tekst, dus korter en losser dan schrijftaal, maar dezelfde B1-norm.
Richtlijn: 75-95 woorden per video van ~30 seconden.

- Eén boodschap per video. Bij twijfel: opknippen.
- Bedragen uitschrijven zoals ze klinken ("1.500 euro", niet "€ 1.500") —
  stemsynthese leest eurotekens vaak verkeerd voor. In beeldtekst wél € 1.500.
- Geen begroeting, geen afsluiting. De kijker zit al in het onderwerp.
- Eindig met wat de kijker nu kan doen of wat er hierna komt.

De Turkse variant is een **eigen script**, geen vertaling: andere voorkennis,
andere drempels. Zie `docs/DECISIONS.md`.

## Wat we nooit zeggen

- Juridische formuleringen zonder uitleg ("conform artikel…", "beschikking").
- "Helaas" of "wij betreuren" — zeg wat er aan de hand is en wat je nu kunt doen.
- Beloftes over doorlooptijden die we niet hard hebben. Getallen komen van
  denhaag.nl, niet uit een schatting.
- Uitroeptekens.
