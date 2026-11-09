# Product — DH App

## Wat het is

Een **prototype** van een gemeente-app voor Den Haag. Native iOS/SwiftUI.
Data is grotendeels dummy, DigiD is nagebootst. Het doel is niet een werkend
product, maar materiaal om mee te testen en beslissingen mee af te dwingen.

## Waar het over gaat

Het onderzoek achter dit prototype (research en PIP-kaarten staan in de
strategie-repo, niet hier) wijst steeds naar dezelfde vier dingen:

1. **Status is de grootste pijn.** Mensen weten niet waar hun aanvraag is en
   krijgen daar geen bericht over.
2. **Procedures en besluiten zijn onbegrijpelijk.** Het jargon zelf is de
   drempel — niet alleen de inhoud. 62% van de inwoners verwacht dat een app
   helpt informatie te begrijpen.
3. **De gemeente informeert niet proactief.** Je moet alles zelf komen halen.
4. **Niet-Nederlandstaligen en laaggeletterden vallen buiten de boot.** Dit is
   tegelijk het grootste gat in het bewijs: veel bronnen zeggen dát het nodig
   is, geen enkele zegt hóe, en de doelgroep is nooit gericht bevraagd.

## Waar het prototype voor dient

- **Aan tafel bij developers**: complexiteit en t-shirt sizing bespreken aan de
  hand van iets werkends in plaats van een plaatje.
- **Bij gebruikerstests**: gedrag meten via Firestore-analytics, en het
  testverslag-dashboard (los Node-project, live op Vercel).
- **Als bewijsmateriaal** voor onderdelen waar het onderzoek nog geen antwoord
  op heeft — de uitlegvideo's zijn daar het duidelijkste voorbeeld van.

## Scope

**Wel:** vier tabs (home · regelen · buurt · hulp), onboarding met nagebootste
DigiD, statuskaarten, een aantal detailschermen, taalwissel NL/EN/TR,
voorleesfunctie, AI-chat in Regelen, uitlegvideo's bij kwijtschelding.

**Niet:** echte koppelingen, echte authenticatie, echte betalingen, consent- en
privacyflows, toegankelijkheidscertificering. De complexiteit van het écht maken
zit in de aggregatielaag achter de app, niet in de app zelf.

## Doelgroep van de tests

Inwoners van Den Haag, met nadruk op de groepen die in het onderzoek
ondervertegenwoordigd zijn: niet-Nederlandstaligen, laaggeletterden, mensen met
lage digitale vaardigheden, en mensen met geldzorgen (kwijtschelding).
