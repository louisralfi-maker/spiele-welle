# Lanternhold 1.0: the store screenshots (plan)

Draft of the store lane (14.11.2026). Eight landscape screenshots that sell the look, each with a caption in eight
languages. The captures come after the rebuild (the world, the hall stage, touching the world, the new interface),
from UI tests on the runner, never on this Mac. Captions are at most 40 characters; `check_listing.py` counts them.

## Sizes (Apple, checked 14.11.2026)

- **6.9-inch** ("iPhone with Dynamic Island (large display)": iPhone 17 Pro Max, Air, 16 Pro Max and others):
  **2868 x 1320** landscape (2796 x 1290 and 2736 x 1260 also accepted). Capture on the runner's iPhone 17 Pro Max
  simulator (CLAUDE.md: fine there, never on this Mac).
- **Apple's help page now names "iPhone with Dynamic Island (medium display)" as the one required iPhone size** ("To
  submit your app, you must provide screenshots for ... iPhone: At least one screenshot for iPhone with Dynamic Island
  (medium display)"): iPhone 17 Pro, 17, 16 Pro and others, **2622 x 1206** landscape (or 2556 x 1179). The
  runner's default simulator, the iPhone 17 Pro, captures exactly 2622 x 1206. The store checklist still says the
  6.9-inch set is the required one; that was true before. Plan: capture the same eight shots on both simulators and
  upload both sets (the 6.9-inch set for the large phones, the 6.3-inch set to satisfy the requirement).
- 1 to 10 screenshots per size; `.png` or `.jpeg`; no alpha channel. XCUITest landscape captures carry EXIF
  orientation 8: make upright copies (through the art lock) before anything else.

## The caption strip

A strip in the game's own hand (docs/UI-look.md): a parchment slip across the top 18 % of the frame, IM Fell English
in ink (`38281A`) on parchment (`ECDCB1`), a teal rule (`1F5C5E`, House Lantern's colour) under it, the game frame
below, uncropped. IM Fell has no Japanese or Chinese glyphs: ja and zh-Hans use a Mincho or Song serif (Hiragino
Mincho, Songti SC) at the same size. The gameplay frame keeps the HUD of the new interface (Apple: screenshots show
the app in use). Composition is a later step (store-2), run through the art lock or on the runner.

## The eight shots

Arguments are the build-86 launch arguments (DESIGN.md "Debug launch arguments") as a starting point; the rebuild
changes the camera (world-3: set pieces at the beacon 470, the front gate 1360, the hall door 1830, the back gate
2330), so frame each shot by eye on the new build. Every shot adds `-GWNoAds YES -GWSkipOnboarding YES
-GWFreezeTime YES -GWLord lady -GWLordName Wren` (one shot of the lady is enough to show the choice: shot 2; the
others may use the lord). Order matters: in search results a landscape listing shows only the first.

### 1. The hold at night (the hero)

The castle wedged in the cleft at night, the battle in front of it: braziers' pools of warm light on the gorge floor,
fire arrows in flight, creatures smouldering at the edge of the light, archers on the wall walk, the keep's lit
windows above. Start: `-GWNight 12 -GWBuild demo -GWHour 22 -GWCameraX 1150 -GWGloomFog 0.6`.

```captions
en: Hold the one gap in the mountains
de: Halte die einzige Lücke im Gebirge
fr: Tenez l'unique brèche des montagnes
es: Defiende el único paso de la montaña
it: Difendi l'unico varco tra i monti
pt-BR: Defenda a única passagem das montanhas
ja: 山の壁に開いた、ただひとつの裂け目を守れ
zh-Hans: 守住群山之墙上唯一的裂隙
```

### 2. Judgment in the great hall

The hall stage: the lady seated on the throne, a petitioner before the dais, the letter and its choices along the
floor band, the hearth's long warm pool, candles on the benches, the house banners. Start: `-GWScreen petition`
(the herald on day 17 at the golden hour) or `-GWDay 6 -GWClock 10` and an audience, with `-GWHouses all`.

```captions
en: Judge your people from the throne
de: Sprich Recht vom Thron aus
fr: Rendez la justice depuis le trône
es: Imparte justicia desde el trono
it: Giudica il tuo popolo dal trono
pt-BR: Julgue seu povo do alto do trono
ja: 玉座から民の訴えを裁け
zh-Hans: 登上宝座，裁决百姓的请愿
```

### 3. Building by day

The gorge floor in clear morning light, builders at work on a wall under scaffolding, a plot's build card (the ledger
page) open with walls, towers and braziers and their prices. Start: `-GWBuild raise -GWDay 8 -GWClock 9
-GWWeather clear`, then touch a plot.

```captions
en: By day, build walls, towers and fires
de: Bei Tag: Mauern, Türme und Feuer bauen
fr: Le jour, bâtissez murailles et feux
es: De día, levanta murallas y hogueras
it: Di giorno, erigi mura, torri e fuochi
pt-BR: De dia, erga muralhas, torres e fogo
ja: 昼は城壁と塔とかがり火を築け
zh-Hans: 白天修筑城墙、塔楼与火盆
```

### 4. The rule of light

Close on one line at night: a wave held at the edge of a brazier's pool, the lit creatures slowed and under fire, the
unlit ones dark shapes with ember cracks beyond the edge band. The picture must teach the rule without a word. Start:
`-GWNight 14 -GWBuild demo -GWHour 23 -GWCameraX 700`.

```captions
en: The Gloom shrinks from light
de: Die Düsternis weicht vor dem Licht
fr: Les Ténèbres reculent devant la lumière
es: La Tiniebla huye de la luz
it: La Tenebra arretra davanti alla luce
pt-BR: A Treva recua diante da luz
ja: 煙の影は光を恐れる
zh-Hans: 烟影畏惧光芒
```

### 5. The valley town at the golden hour

Past the back gate: the town under open sky, houses, market and tavern, citizens in the lanes, the river and the far
mountains, the first windows lit. Start: `-GWDay 10 -GWBuild demo -GWClock 18 -GWCameraX 3000 -GWWeather breeze`.

```captions
en: A valley town worth every night
de: Eine Stadt, die jede Nacht wert ist
fr: Une vallée qui vaut chaque nuit
es: Un valle que merece cada noche
it: Una valle che vale ogni notte
pt-BR: Um vale que vale cada noite
ja: 守る価値のある谷の町
zh-Hans: 值得守护的山谷小镇
```

### 6. The court

The lord in the bailey or at the hall door at dusk, lantern in hand, talking to a court member, the speech bubble
over the speaker, the hall door's warm light on the cobbles. Start: `-GWDay 9 -GWClock 18.5 -GWCameraX 1830`, then
touch Tamsin or Brannock.

```captions
en: A court with secrets of its own
de: Ein Hof voller Geheimnisse
fr: Une cour aux mille secrets
es: Una corte llena de secretos
it: Una corte piena di segreti
pt-BR: Uma corte cheia de segredos
ja: それぞれに秘密を抱えた宮廷
zh-Hans: 宫廷里人人都藏着秘密
```

### 7. The Great Beacon

Night 20: the beacon ablaze at the cleft's mouth, its huge steady pool over the front, the Lightless King in its
light with his aura breaking, the night full of arrows. Start: `-GWNight 20 -GWHour 20.6 -GWCameraX 760` (the King
leaves at about 20:20); the reference bot's realm must have the beacon finished, as T6 assumes (`-GWBuild demo` alone
leaves it at stage 2, so do not use it here, or finish the beacon first). It shows the King, whom the description
names; it spoils no ending.

```captions
en: Only the Beacon's light can wound him
de: Nur das Leuchtfeuer kann ihn verwunden
fr: Seul le Grand Fanal peut le blesser
es: Solo la Gran Almenara puede herirlo
it: Solo il Grande Faro può ferirlo
pt-BR: Só o Grande Farol pode feri-lo
ja: 王を討てるのは大烽火の光だけ
zh-Hans: 唯有大烽火之光能伤及无光之王
```

### 8. First light

Dawn sweeping in from the right: gold light over the walls, the last creatures dissolving into soot, smoke from the
braziers, mist lifting. Start: `-GWNight 12 -GWBuild demo -GWHour 5.83 -GWCameraX 900` (DESIGN.md's own example
holds first light's front at the outer wall).

```captions
en: Hold until first light
de: Halte durch bis zum Morgengrauen
fr: Tenez jusqu'aux premières lueurs
es: Resiste hasta el alba
it: Resisti fino alle prime luci
pt-BR: Resista até o amanhecer
ja: 夜明けまで持ちこたえろ
zh-Hans: 坚守到黎明
```

## The bar for each frame

- A clear focal point, three depths, warm light against cold dark (DESIGN.md "Art bar").
- Nothing clipped, no debug overlay, no test text, no placeholder sprite, no crown symbol left on a button (digest
  section 5), no ad on screen.
- German text in the frame fits; ja and zh-Hans frames come from runs in those languages once the interface strings
  are translated (after the join).
- Readable on a phone: judge each frame at the size of a search result before choosing it.
