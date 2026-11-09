# Besluitlog — DH App

Append-only. Nieuwe besluiten onderaan, met datum. Nooit herschrijven.

> Dit log is op 2026-08-05 aangelegd bij het splitsen van een uitgedijde
> `CLAUDE.md` in de driedeling (CLAUDE.md · DECISIONS.md · VOICE.md).
> Deze repo staat **niet** onder git; de versie van vóór de split staat als
> kopie in `docs/CLAUDE-md-2026-08-05-voor-split.md`.
> De besluiten hieronder met datum "≤ 2026-08-04" zijn achteraf gereconstrueerd
> uit die oude CLAUDE.md — de oorspronkelijke datums zijn niet bekend.

---

## ≤ 2026-08-04 · Onboarding wordt bij elke koude start opnieuw getoond

De app-gate gebruikt in-memory `@State didCompleteOnboarding`, geen
`@AppStorage`. Bewust: bij demo's wil je elke keer de volledige flow kunnen
laten zien. Tijdens gebruik blijf je wél in de app.

Terugdraaien is één regel (`@AppStorage("didCompleteOnboarding")`).

## ≤ 2026-08-04 · Tabs worden alleen horizontaal geclipt

`HorizontalClip` neemt volledige breedte maar loopt verticaal ver buiten bounds
door.

**Waarom:** `scrollClipDisabled`-carrousels lekten naar andere tabs. Een gewone
`.clipped()` op de content-ZStack loste dat op, maar knipte op het toestel de
gele notch-header weg en sneed de buurt-kaart aan de onderkant af.

## ≤ 2026-08-04 · Buurt-kaart op Apple MapKit met CARTO-tiles

MapKit als basis, CARTO Positron no-labels als tile-overlay
(`canReplaceMapContent = true`).

**Waarom:** de minimale Figma-look was met kale MapKit niet te halen. Volledig
overstappen op externe tiles gaf een privacy-afweging die we niet wilden maken
voor een prototype. Tiles laden via subdomein-rotatie a/b/c/d — één host
throttelde en liet tegels half laden.

## ≤ 2026-08-04 · Camera-overgang op de kaart is bewust traag

`UIView.animate(withDuration: 1.1, .curveEaseOut)` in plaats van de korte
default `setRegion(animated:)`. Rustiger beeld; de standaard voelde schokkerig.

## ≤ 2026-08-04 · Foto's voor buurt, illustraties voor home

Buurt-kaarten gebruiken echte foto's (`foto-*`), home-tegels en onboarding
gebruiken illustraties (`ill-*`). Bewust onderscheid: de buurt gaat over de
echte stad, de springplank over functies.

## ≤ 2026-08-04 · Analytics zonder consent-flow

`AnalyticsService` logt sessies, schermen en taps naar Firestore zonder
toestemming te vragen. Bewust voor het prototype — bij een echte uitrol is dit
het eerste wat moet veranderen.

---

## 2026-08-05 · Uitlegvideo's zitten ín het onderwerp, niet in een videosectie

Drie korte portrait-video's (~25-35 sec) die kwijtschelding uitleggen, staan als
kaart in `KwijtscheldingDetailView` — boven de voortgangstijdlijn, onder de
verwachte afhandeldatum.

**Waarom:** een aparte videosectie is het patroon waaraan stadsapps ten onder
gaan (zie `inz-waarom-stadsapps-falen` in de strategie-vault): een content-silo
die je moet wíllen bezoeken. Niemand opent een gemeente-app om een filmpje te
kijken. Mensen lopen vast op een pagina en hebben dáár uitleg nodig.

## 2026-08-05 · De taalknop staat in de speler, niet in de app-instellingen

De speler toont NL/TR-knoppen rechtsboven, zichtbaar voor iedereen, met de
app-taal als startwaarde.

**Waarom:** wie uitleg in eigen taal nodig heeft, heeft de app-taal vaak niet
omgezet — de telefoon is ingesteld door een kind of staat gewoon op Nederlands.
De taalkeuze achter een instellingenscherm zetten betekent dat precies de
doelgroep waarvoor de Turkse video bestaat, hem nooit vindt.

Onderliggend inzicht (`inz-taalbarriere`) staat bewust op zekerheid 50: vijf
bronnen zeggen dát het nodig is, geen enkele zegt hóe, en de doelgroep is nooit
bevraagd. Deze feature is het instrument om dat gat te dichten — daarom logt de
speler `video_open` en `video_taal` naar Firestore.

## 2026-08-05 · Turkse video is een eigen opname, geen vertaling

`ExplainerVideo.bestanden` is een dictionary per taal met losse bestanden; er is
geen ondertitel- of dubbing-mechanisme.

**Waarom:** een Turkse kijker heeft andere voorkennis nodig (wat is die
belasting überhaupt, wat betekent het Nederlandse woord "kwijtschelding" dat op
de brief staat). Woord-voor-woord vertalen test vooral of de stemsynthese goed
Turks spreekt, niet of de uitleg landt.

**Openstaand risico:** de Turkse tekst is geschreven zonder controle door een
moedertaalspreker. Niet gebruiken buiten interne demo's voordat dat gebeurd is.

## 2026-08-05 · Poster-frames worden runtime uit de video gehaald

`ExplainerCardView` genereert thumbnails met `AVAssetImageGenerator` op t=0,6s,
in plaats van losse thumbnail-assets bij te houden.

**Waarom:** scheelt handwerk en houdt de thumbnail automatisch in sync als een
video wordt vervangen. t=0,6s en niet t=0 omdat het eerste frame vaak nog een
lege fade-in is.

**Bijwerking:** de drie delen zijn opgenomen in dezelfde setting met dezelfde
avatar, dus de drie thumbnails lijken sterk op elkaar. Als dat in gebruikerstest
verwarrend blijkt, is een vast tijdstip per deel of een eigen poster de fix.

## 2026-08-05 · Video's als platte bundle-resources

In `project.yml` toegevoegd als `path: DenHaag/Resources/Video` met
`buildPhase: resources`, bewust **zonder** `type: folder`.

**Waarom:** met `type: folder` wordt het een folder-reference en moet je
`Bundle.main.url(forResource:withExtension:subdirectory:)` gebruiken. Plat in de
bundle werkt de gewone lookup. Kost ~84 MB app-grootte voor vier clips; voor een
demo-build acceptabel.

## 2026-08-05 · Kwijtscheldingsscherm was onbereikbaar — statuskaart toegevoegd

`HeaderView` declareerde `onKwijtscheldingTapped`, maar riep hem nergens aan.
`KwijtscheldingDetailView` was dus dode code: gebouwd, niet te openen.

Opgelost met een vierde statuskaart in de home-carrousel ("Status kwijtschelding
· Je aanvraag is in behandeling") en een `.kwijtschelding` case in
`HomeCardAction`.

**Waarom deze plek:** het detailscherm toont een lópende aanvraag met tijdlijn.
Dat hoort in de rij "dit loopt er nu voor je", niet op een springplank-tegel.

**Faalverhaal:** dit kwam pas boven water bij het testen in de simulator — de
build slaagde, de code compileerde, en niets wees erop dat het scherm
onbereikbaar was. Een callback die nergens wordt aangeroepen is geen
compilerfout.

## 2026-08-05 · Behandeltermijn kwijtschelding: 13 weken, niet 8

`kw_info_1` stond in alle drie de talen op "maximaal 8 weken". denhaag.nl geeft:
ontvangstbevestiging binnen 10 dagen, besluit binnen 13 weken. Gecorrigeerd naar
13.

**Bron:** https://www.denhaag.nl/nl/belastingen/kwijtschelding-belastingen-aanvragen-of-regelen/

De scripts van de video's volgen dezelfde bron. Andere getallen die daaruit
komen: spaargeldgrens € 1.500 (alleenstaand) / € 2.000 (gezin), auto boven
€ 3.350 telt als vermogen, bezwaar binnen 10 dagen na het besluit.

**Bewust niet overgenomen:** het percentage bij gedeeltelijke kwijtschelding.
De 76,5% die op niet-officiële sites rondgaat, staat niet op denhaag.nl en komt
uit de regeling van een andere gemeente.

## 2026-08-05 · Eén AVPlayer voor de hele reeks, geen speler per video

`ExplainerPlayerView` houdt één `AVPlayer` aan en wisselt per deel alleen het
item (`replaceCurrentItem`). Het einde van een video wordt opgemerkt met
`.onReceive` op de `AVPlayerItemDidPlayToEndTime`-publisher, gefilterd op het
item dat nu speelt.

**Waarom:** de eerste versie maakte per video een nieuwe `AVPlayer` en hield de
notificatie-tokens handmatig bij in `@State`. Die administratie liep uit de pas
met de SwiftUI-state: bij "volgende video" sprong de header wél naar deel 2,
maar bleef het eindscherm staan en speelde er niets. Met één speler en de
publisher is er niets meer bij te houden.

## 2026-08-05 · "Opnieuw kijken" verwijderd — oorzaak niet gevonden

De knop sloot de fullScreenCover in plaats van de video te herstarten.
Reproduceerbaar, ook na herbouw.

**Wat is uitgesloten** (elk apart getest in de simulator):
- Niet `start()`: direct `speelAf()` aanroepen gaf hetzelfde gedrag.
- Niet de synthetische `Binding(get:set:)` van `fullScreenCover(item:)`:
  overstappen op `fullScreenCover(isPresented:)` met een losse `startVideo`
  maakte het erger — daarna viel het scherm zelfs zónder tap terug op wit.
- Niet AVKit's `VideoPlayer`: vervangen door een kale `AVPlayerLayer`-wrapper
  veranderde niets.

Alle drie de wijzigingen zijn teruggedraaid naar de combinatie die aantoonbaar
werkt (item-cover + `VideoPlayer`). De knop is uit de eindkeuze gehaald.
"Volgende video" en "Sluiten" werken, en het einde van de reeks toont "Je hebt
alle video's gezien."

**Les:** na twee fixes zonder vastgestelde oorzaak was het beter geweest te
stoppen en te meten dan een derde te proberen — elke gok maakte de toestand
onduidelijker. Terugzetten van de knop vraagt eerst een diagnose (logging op de
knop-actie en op de cover-dismiss), niet nog een hypothese.

## 2026-11-03 · Vier versies (V1/V2/V3/Prototype testen) vervangen Basis/Uitgebreid/Volledig

`Models/AppVersie.swift` is de enige plek die bepaalt wat een versie toont.
V1 = melden + fietsen. V2 = V1 + voor-jou-kop, afval, parkeren, zwemmen,
afspraken, personalisatie. V3 = alles behalve notificaties. "Prototype testen"
is geen opvolger maar een eigen selectie voor gebruikerstests (melden, fietsen,
parkeren, zwemmen, afspraken, voor jou, personalisatie, regelen, en sinds
2026-11-04 ook buurtleven en participatie).

Elke versie heeft een **vaste tegellijst** (`AppVersie.tegels`). V1 heeft geen
"Startscherm aanpassen". Een versie kiezen brengt je direct naar home met de
tegels van die versie.

**Weg:** Dappre-koppeling (de code blijft, `dappre` geeft altijd `.geen`), de
taalwissel in de instellingen (de app is Nederlands; de taalknop in de
videospeler blijft), het berichten-belletje (in geen enkele versie), de
onboarding bij opstarten (start nu vanuit het profielmenu). De testversie vraagt
bij opstarten alleen kort je naam.

**Waarom:** het prototype moet de stappen laten zien van wat als eerste live gaat
naar wat erna komt. De oude indeling volgde de fiets-app-koppeling, niet de
uitrol.

## 2026-11-03 · Meldflow herbouwd naar Figma "prototype MOR '26"

Bron: Figma-bestand `HfvOJp3cD2kSUXPf8Yx3TA`, node 1104-5637. Code in
`Views/Melding/` (`MeldingView`, `MeldingComponenten`, `MeldingModel`,
`MeldingStatusView`). De tegel "Iets melden" opent in elke versie deze flow,
ook in V3 (daar ging hij eerst naar Regelen).

**Bewuste afwijkingen van Figma:**
- Foto's is een eigen stap (wens van Fabian), dus niet in stap "wat".
- Een echte Apple-kaart (gedempt) in plaats van het vaste plaatje.
- Na een tik op een container staat het adres al onderin en kun je door.
- "Foto's" staat op de controle één keer; Figma toont het ook onder Locatie
  (lijkt een kopieerfout).
- Geen meldnummer op het verstuurd-scherm, zoals in Figma.

**Faalverhaal:** de eerste oplevering "kwam totaal niet overeen". De vergelijking
was gedaan met app-screenshots die van 402 naar 393 punt waren geschaald,
waardoor alles een paar procent verschoof en niets eerlijk te meten was. Opnieuw
gedaan op ware puntgrootte (Figma 1x naast simulator ÷3, lijn per 25 pt): toen
bleken regelhoogtes, placeholderkleur, bovenmarge van de intro, de indeling van
de controle (drie kaarten, niet vijf) en de tijdlijn af te wijken.

## 2026-11-03 · Vervolgvragen van een melding: één per scherm

Na "onveilige situatie" krijgt elke vervolgvraag een eigen scherm. Je kiest één
antwoord (groen), Volgende brengt je naar de volgende vraag. Een vraag kan
voorwaardelijk zijn (`MORVraag.alleenBij`): "Waar staat het voertuig?" alleen
bij foutparkeren. De voortgangsbalk loopt per vraag op.

**Waarom:** uit de intervisie van 2026-11-03. Alle vragen op één scherm, met
vragen die erbij kwamen terwijl je klikte, voelde als een formulier dat groeit.

## 2026-11-03 · Ondernemersrol "Kapsalon Anne"

`RolManager` (in `Models/PrototypeStores.swift`) wisselt tussen inwoner en
ondernemer. Je wisselt door in de profielkop te vegen (groen ↔ blauw), niet
meer met een schakelaar. Als ondernemer:
- is de homekop blauw (`facetten-blauw`) met witte tekst, en blijven de knoppen
  op de kaarten groen;
- krijg je eigen kaarten (terras, melding, bedrijfsafval, parkeervergunning) en
  tegels (vergunningen, terras; niet in V1);
- staat de buurtkaart rond je zaak, Hoefkade 12, met een filter "Voor je zaak".
  Dat filter staat in elke versie met een buurtkaart.

**Faalverhaal:** de coördinaat van Hoefkade 12 was eerst geschat en lag 800 m te
noordelijk (bij de Van Mieristraat). Opgezocht via OpenStreetMap: 52.0618,
4.2994, bij de Marktweg. De tekst over laden en lossen noemde daardoor eerst de
Vaillantlaan, die daar niet ligt.

## 2026-11-03 · Chat: eerste tekstblok pakken, niet het eerste blok

`claude-sonnet-4-20250514` gaf een 404; overgestapt op `claude-sonnet-5-5`.
Daarna werkte de chat nog steeds niet: dat model stuurt eerst een (leeg)
denkblok vóór het antwoord, en `ClaudeService` las alleen `content.first`. Ook
kapte `max_tokens: 500` het JSON-antwoord halverwege af. Nu: het eerste blok met
`type == "text"`, en `max_tokens: 1500`.

**Les:** na een modelwissel niet alleen de statuscode testen, maar ook de vorm
van het antwoord. De curl-test gaf 200 en zag er goed uit, terwijl de app er
niets mee kon.

## 2026-11-03 · Buurtkaart opent met jou én de dichtstbijzijnde plek in beeld

Bij vaste plekken (fietsenstallingen) zoomt de kaart zo uit dat je eigen locatie
en de dichtstbijzijnde plek allebei zichtbaar zijn (`BuurtView.regioMet`). Het
stallingkaartje heeft "Fiets erheen · n min", dat Google Maps opent met een
fietsroute.

## 2026-11-04 · Pulsering rond je locatie: zichtbaar, onder de markers

De radar pulseerde, maar zo flauw dat het niet opviel. Nu: drie volle blauwe
ringen (`#1A73E8`) die helder beginnen en pas aan het eind uitdoven, een halo
die ademt, en de radar onder de markers (`zPriority = .min`). `PulseHostView`
start de animatie opnieuw bij `didMoveToWindow` en bij terugkomst uit de
achtergrond, omdat CoreAnimation animaties dan weggooit.

## 2026-11-03 · Simulator-screenshots via simctl, niet via de simulator-tool

De screenshot van de simulator-tool liet een oud beeld zien: een tik was wel
verwerkt, maar het beeld niet ververst. Daardoor leek "Overslaan" niet te
werken. `xcrun simctl io <device> screenshot` geeft de echte stand. De tool
stuurde bovendien eerst een ander toestel aan; geef altijd het device-id mee.

## 2026-11-07 · Meldflow: knop op de controle blijft "Volgende"

Via de beslisbak. De knop op het controlescherm, die de melding verstuurt,
blijft "Volgende", gelijk aan Figma. Het advies was "Verstuur" (zegt wat er
gebeurt); Fabian koos voor Figma. Afweging in OVERWEGINGEN.md (2026-11-03).

## 2026-11-07 · Geen overzicht "Uw meldingen"

Via de beslisbak. Het overzicht uit het huidige MOR-prototype (eigen meldingen
met status, meldingen in de buurt, knop "Nieuwe melding") wordt niet gebouwd.
De meldflow begint bij de tegel "Iets melden", zoals in Figma MOR '26.

## 2026-11-07 · Bieb, vergunningen en terras houden hun icoon

Via de beslisbak. De tegels Naar de bieb, Mijn vergunningen en Terras of
uitstalling krijgen geen eigen illustratie; ze blijven bij het icoon en er
wordt niets aangeleverd. Overzicht in `screens/tegel-illustraties.png`.


## 2026-11-07 · Correctie op de kop van dit log: de repo staat wél onder git

De kop zegt dat de repo niet onder git staat. Dat klopt sinds 2026-10-08 niet
meer: eerste commit op die datum, remote `github.com/fabianvalkenberg/dhapp`,
werkwijze in `docs/SAMENWERKEN.md`. De kopie van vóór de split in
`docs/CLAUDE-md-2026-08-05-voor-split.md` blijft de enige bron voor die versie.

## 2026-11-09 · Eén terugknop, op één plek (design review)

Uit de design review (Figma `wvwF4ED2uW2omIH8vYvDSx`, pagina Prototype v3).
`BackCircleButton` is nu de enige terugknop: 43 pt rond, blauwe Den Haag-pijl,
in drie uitvoeringen naar wat erachter ligt: `.wit` (warm grijs rondje op wit),
`.kleur` (wit met grijze rand op lichtblauw of geel) en `.foto` (glas met witte
pijl, ook op donkergroen/-blauw). Plaatsen met `.terugknopPlek()`: 8 pt onder
de statusbalk, links op de grid-marge.

**Afwijking van Figma:** Figma zet de knop op 24 pt van links, omdat dat
bestand een 24 pt-grid heeft. De app heeft een 20 pt-grid en de reviewnotitie
over parkeren noemt ook 20 pt. De knop volgt het grid van de app.

**Buiten scope gelaten:** het sluit-kruisje bij kwijtschelding (andere functie),
de kop van de meldflow en grofvuil (voortgangsbalk-kop, volgt Figma MOR) en de
fietspas (wordt opnieuw ontworpen).

## 2026-11-09 · Vervaging achter de statusbalk, alleen tijdens scrollen

Uit de design review ("iOS UI"): inhoud liep hard onder klok en batterij door.
`.bovenVervaging()` op de ScrollView van een volledig scherm legt er een blur
met wit verloop over (Figma: 106 pt, wit 92→70→0% op 40%). Hij verschijnt pas
na ~24 pt scrollen, zodat een gele of gekleurde kop in rust niet verbleekt.
Werkt vanaf iOS 18 (`onScrollGeometryChange`); op iOS 17 geen vervaging.

## 2026-11-09 · Testharnas: `-scherm` en `-tab regelen|hulp`

Voor screenshots zonder tikken: `-scherm instellingen|startscherm|afspraak|
parkeren|afval|afvalkalender|kwijtschelding|aanvraag|paspoort|berichten|
vergunningen|meldingstatus` opent dat detailscherm direct.
