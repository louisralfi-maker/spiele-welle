# Lanternhold: the translators' glossary

For the six languages that follow English and German: French (fr), Spanish (es), Italian (it), Brazilian Portuguese
(pt-BR), Japanese (ja) and Simplified Chinese (zh-Hans). Scope: the story texts in `Resources/Story.xcstrings`
(petitions, choices, reactions, Odile's counsel, court lines, speakers, remembered lines, endings; 882 keys). The
interface strings (`Localizable.xcstrings`) follow after the rebuild and take their terms from this file.

Everything here is decided. Where a translator thinks a decision reads wrong in a real text, the translator keeps the
decision, finishes the batch and reports the case in the batch notes; the lead changes the glossary, never a
translator alone. Sources: STORY.md (the world, the people, the German names), DESIGN.md "Languages and text", and the
German catalog, which was written alongside the English by the same writers and settles what the English leaves open
(section 9).

Contents: 1 rules for every language · 2 the voice · 3 the lord who may be a man or a woman · 4 address · 5 each
voice in Japanese and Chinese · 6 fixed terms · 7 names · 8 punctuation · 9 when the German decides · 10 numbers,
money, time · 11 names still to come (prologue, endings).

---

## 1. Rules for every language

1. **English is the source of meaning.** The German decides only what the English leaves open (section 9). If the
   two disagree in content, follow the English and note the key.
2. **One picture, one turn.** Texts are read on a phone between two nights. Keep the English length or less; cut a
   second adjective before a fact. The budgets are in `i18nlib.py` and `check.py` enforces them.
3. **"Lantern" is never translated**, in the house's name or the castle's (Lanternhold); in Japanese and Chinese it
   is transcribed once and for all (section 7). The object is translated as usual (section 6).
4. **Names of people, houses and towns are never translated** (section 7). Only Ser Ludo's tall tales are
   translated, as the German does (section 6, "Ser Ludo's boasts").
5. **No king, no crown, nothing royal on our side.** The lord is a Burgherr or Burgherrin with a circlet. The only
   king is the Lightless King and the only crown is his. Words that must never describe our side:

   | Language | Never for our side |
   |---|---|
   | fr | roi, reine, couronne, couronnement, majesté, sire, royaume, règne, trône royal, altesse |
   | es | rey, reina, corona, coronación, majestad, reino, reinado, alteza |
   | it | re, regina, corona, incoronazione, maestà, regno, altezza |
   | pt-BR | rei, rainha, coroa, coroação, majestade, reino, reinado, alteza |
   | ja | 王, 女王, 陛下, 殿下, 王冠, 冠, 王国, 玉座, 即位, 治世, 殿 (as an address) |
   | zh-Hans | 王, 女王, 陛下, 殿下, 王冠, 冠, 王国, 王座, 宝座, 登基, 朕, 本王 |

   "Throne" stays for the lord's chair in the Romance languages (trône, trono) as in English and German; Japanese
   and Chinese use the non-royal words of section 6.
6. **The lord's sex is the player's choice** and every text must read right for both (section 3). English never
   says he or she about the lord; no translation adds a pronoun the English avoided.
7. **Puns and rhymes are recreated, never translated word for word**, as the German does ("lantern" with "anthem"
   became "Laterne" with "Ferne"; "Your Wickship" became "Eure Dochtheit"). The fixed ones are in section 6.
8. **No music.** The bard's songs are words on a card; "tra la" stays a sung nonsense syllable (fr "tra la la", es
   "tralará", it "trallallà", pt "tra-lá-lá", ja 「ららら」, zh "啦啦啦"). Never promise a tune.
9. **Dread, not gore.** No blood, no cruelty played for a laugh. **No creature is ever called a child**, in any
   word (ja never 子 or 童 for a creature, zh never 小孩, 孩子 or 童 for one). The Returned say household things and
   nothing else.
10. **Original names only.** The creature names of section 6 were chosen to be our own. Never borrow a name from
    another game, book or film, in any language (in Japanese never ススワタリ or まっくろくろすけ for the sootlings).
11. **Never add or drop a fact.** No explanations the English does not give (rule 8 of STORY.md: hints are things
    seen; nobody theorises).

---

## 2. The voice

**For every language, in two sentences:** a medieval court heard today: people speak plainly, in short sentences,
dry and warm at once, the way people now would talk if they lived by a wall in the dark. The past lives in the
things (lanterns, tithes, a circlet, a horn), never in the grammar: no thee-and-thou archaism, no fantasy grandeur,
no modern slang, office words or jokes that wink at the player.

What that means in each language:

- **fr:** the French of a good contemporary novel set in the Middle Ages: vous between adults, plain verbs, the
  passé composé in speech and the présent in the reactions, as the English uses the present. Never "oyez", "messire"
  (except where section 4 says so), "point de", the passé simple in speech, nor "super", "OK", "stresser".
- **es:** one neutral Spanish that reads right in Madrid and in Mexico City: usted and ustedes, never vosotros, never
  voseo, no regional words ("vale", "guay", "chévere", "platicar"). Never "vuestra merced", "os", "aqueste"; the
  period comes from the nouns.
- **it:** the Italian of a good historical novel: voi as the respectful form, short sentences, the passato prossimo
  in speech. Never "messere", "codesto" or archaic endings, never anglicisms or colloquial fillers ("ok", "tipo",
  "figo").
- **pt-BR:** Brazilian Portuguese as a careful historical novel writes it: "o senhor / a senhora" from the court,
  "você" from the narrator and the lord, Brazilian pronoun placement in speech ("Me dê", "Se sente") and plain
  standard in narration (no mesoclisis). Never European forms ("tu" with its verb, "rapariga"), never "vós",
  "vosmecê", nor slang ("cara", "beleza", "tipo").
- **ja:** the Japanese of a carefully translated European historical novel: polite keigo from the court, the plain
  form from the lord, no samurai vocabulary (殿, 拙者, ござる, 御意, 殿様) and no anime role-speech (〜じゃ,
  〜でござる, 〜ですわ, 〜なのだ). Common kanji (常用漢字), kana where kanji would be heavy; katakana only for names
  and the fixed loanwords of this file (ランタン, サー, デイム, マザー).
- **zh-Hans:** modern standard written Chinese with a light literary touch, as in a good translation of a European
  historical novel: 您 for the lord, short sentences, four-character idioms only now and then. No internet slang, no
  wuxia or palace-drama clichés (在下, 汝, 尔等, 本王, 奴婢, 娘娘, 微臣), mainland vocabulary only.

Each person keeps their own voice in every language (STORY.md rule 7): Odile dry, Brannock short, Pip sideways,
Hesper calm and a little ominous, Tamsin warm and informed, Bram nearly silent, Marek smooth, Seren far away, Ludo
sincere and grand, the herald courteous and cold, Dame Orla old and unafraid. Section 5 fixes how each one sounds in
Japanese and Chinese, where the speech style carries most of the voice.

---

## 3. The lord who may be a man or a woman

The player types a name and chooses Burgherr or Burgherrin. The catalog has two placeholders (Core/Lord.swift
`LordText`), and every language uses exactly these:

- **`{lord}`** is the typed name (up to 16 letters of any script). It appears exactly as often as in the English
  (check.py errors otherwise). Never put an article before it or a word that changes with the name's first letter:
  fr no `de {lord}`, `que {lord}`, `le {lord}` (elision); it no `lo/la {lord}`; pt-BR no `o/a/do/da {lord}`; es avoid
  `y {lord}`, `o {lord}`. Write `pour {lord}`, `à {lord}`, a comma, or rephrase.
- **`{a|b}`** reads *a* for the Burgherr and *b* for the Burgherrin. Rules:
  1. Lord first, lady second, always.
  2. Whole words only; put the whole phrase that changes in the group, from its first changing word to its last,
     and keep what stays the same outside: `{prêt|prête}`, `{du seigneur|de la dame}`, never `prê{t|te}`.
  3. Nothing nests, and `{lord}` never stands inside a group: `{lord}{卿|}` is legal, `{Lord {lord}|...}` is not.
  4. Both halves are complete and read naturally on their own. A half may be empty only where the other language
     form needs no word at all.
  5. Capitalise both halves at the start of a sentence.
  6. A group whose halves are the same is written once, without braces (check.py warns).
- **English** writes around pronouns and uses groups only for address and titles (`my {lord|lady}`,
  `{Lord|Lady} Lantern`, Brannock's `{lord|my lady}`, once `{his|her}`). **German** adds groups wherever grammar
  agrees (`{der neue Herr|die neue Herrin}`, `{derjenige|diejenige}`). Do as German does, for your own grammar.

What takes a group, by language:

| Language | Takes a group | Needs none |
|---|---|---|
| fr | vocatives and titles; the noun for the lord (seigneur / dame, lampiste's article: `{le|la} lampiste`); every adjective and past participle that agrees with the lord, in speech and in the narrator's reactions alike (`{prêt|prête}`, `vous êtes {venu|venue}`, `vous voilà {seul|seule}`); articles and contractions before such a noun (`{du|de la}`, `{au|à la}`); il / elle when the lord is spoken of | vous and its verbs; possessives (son, sa follow the thing owned) |
| es | vocatives and titles; señor / señora; adjectives and participles agreeing with the lord (`{cansado|cansada}`); farolero / farolera with its article; él / ella | usted and its verbs; su / sus |
| it | vocatives and titles; signore / signora; adjectives and participles agreeing with the lord (`siete {stanco|stanca}`, `{arrivato|arrivata}`); `{figlio|figlia} della casa`; lampionaio / lampionaia with its article; lui / lei | voi and its verbs; vostro / vostra (follow the thing owned) |
| pt-BR | vocatives and titles; `{o senhor|a senhora}` used as "you"; adjectives and participles agreeing with the lord (`{pronto|pronta}`); `{filho|filha} da casa`; acendedor / acendedora de lampiões with its article; ele / ela | você and its verbs; seu / sua (follow the thing owned) |
| ja | almost nothing: honorifics are the same for both (城主様). A group only where the English turns on the lord's sex in a way Japanese must show (the {his|her} line needs none: Japanese drops the pronoun) | 城主, 城主様, あなた, every verb |
| zh-Hans | 他 / 她 when the narrator or a speaker refers to the lord in the third person (`{他|她}`); nothing else | 您, 你, 大人, 城主 |

Examples from the catalog:

| Key | English | How the target writes it |
|---|---|---|
| `line.odile_first_day` | A circlet is a hat that argues back, my {lord\|lady}. Sit when you are ready. | fr: … qui discute, {monseigneur\|madame}. Asseyez-vous quand vous serez {prêt\|prête}. · es: … {mi señor\|mi señora}. Siéntese cuando esté {listo\|lista}. · it: … {mio signore\|mia signora}. Sedete quando sarete {pronto\|pronta}. · pt-BR: … {meu senhor\|minha senhora}. Sente-se quando estiver {pronto\|pronta}. · ja: …帽子でございます、城主様。お心が決まりましたら、お掛けください。 · zh-Hans: ……帽子，大人。您准备好了，就请坐吧。 |
| `line.pip_matches` | They made the lamplighter {lord\|lady}. | fr: On a fait {du lampiste un seigneur\|de la lampiste une dame}. · es: Hicieron {señor al farolero\|señora a la farolera}. · it: Hanno fatto {signore il lampionaio\|signora la lampionaia}. · pt-BR: Fizeram {do acendedor de lampiões um senhor\|da acendedora de lampiões uma senhora}. · ja: 灯り番が城主になったのです。 · zh-Hans: 他们让点灯人当了城主。 |
| `petition.herald_demand.text` | … greets the lamplighter on {his\|her} borrowed chair. | fr: … salue {le\|la} lampiste sur son siège d’emprunt. · ja: …借り物の椅子に座る灯り番に、ご挨拶申し上げます。 · zh-Hans: ……向坐在借来椅子上的点灯人致意。 |

---

## 4. Address

### 4.1 Who says "you" how

| | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|
| The court, guests and petitioners to the lord | vous | usted | voi | o senhor / a senhora (prefer dropping the pronoun; the verb shows it) | keigo; no pronoun, or 城主様 as "you" (never あなた, 君, お前) | 您 |
| The narrator to the lord (reactions, remembered lines, endings) | vous | usted (drop the pronoun where the verb is clear) | voi | você | no pronoun; あなた only where a subject is unavoidable | 你 |
| The lord to adults | vous | usted, ustedes | voi | você; o senhor / a senhora to the old (Dame Orla, Mother Hesper, old Hemmet, the widow) | plain form (常体); です・ます to the old (same four) | 你; 您 to the old (same four) |
| The lord to a child, and to Pip once at his farewell (`petition.pip_farewell.c1`, as the German "du") | tu | tú | tu | você (as to everyone; the warmth is in the words) | plain form, softer (〜ね, 〜よ) | 你 |
| Dame Orla to the lord (she sits down unasked) | vous | usted | voi | você (an old woman to a young one) | plain form, the only speaker who uses it to the lord | 你, the only speaker who uses it to the lord |
| Among court members, about each other | names as in English | names | names | names | bare names, offices where the English gives them (ブラノック隊長) | bare names, offices where given (布兰诺克队长) |
| Townsfolk about court members | as English | as English | as English | as English | オディール様, マザー・ヘスパー, ブラノック隊長; Pip and Marek bare | 奥黛尔大人, 赫斯珀嬷嬷, 布兰诺克队长; Pip and Marek bare |

The lord refers to themself as fr je, es yo, it io, pt-BR eu, ja 私 (わたし), zh-Hans 我; never a royal "we" (nous,
nosotros, noi as majesty; 余, 朕, 本王, 本座).

### 4.2 The words of address

The English and German forms decide which word belongs to whom (the German distinguishes the town's "Burgherr", the
soldiers' "Herr" and the court's "mein Herr"; it gives House Lantern's own lords the title Burgherr and keeps the
foreign "Lord / Lady" for the other houses and for the outsiders who address the lord politely).

| Who, and the English | German | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| Court (Odile, Tamsin, Finch …): my {lord\|lady} | {mein Herr\|meine Herrin} | {monseigneur\|madame} | {mi señor\|mi señora} | {mio signore\|mia signora} | {meu senhor\|minha senhora} | 城主様 | 大人 |
| Townsfolk and petitioners: my {lord\|lady} | {Burgherr\|Burgherrin} | {monseigneur\|madame} | {mi señor\|mi señora} | {mio signore\|mia signora} | {meu senhor\|minha senhora} | 城主様 | 城主大人 |
| Brannock and soldiers: {lord\|my lady} | {Herr\|Herrin} | {monseigneur\|madame} | {señor\|señora} | {signore\|signora} | {senhor\|senhora} | 城主 (bare, like 隊長) | 城主 (bare) |
| Ser Ludo: good my {lord\|lady} | {edler Herr\|edle Herrin} | {mon bon seigneur\|ma bonne dame} | {mi noble señor\|mi noble señora} | {mio nobile signore\|mia nobile signora} | {meu nobre senhor\|minha nobre senhora} | 気高き城主殿 (the one 殿, his old-fashioned flourish) | 尊贵的大人 |
| Mother Hesper: child of the house | Kind des Hauses | enfant de la maison | {hijo\|hija} de la casa | {figlio\|figlia} della casa | {filho\|filha} da casa | 家の御子 | 家族之子 |
| Pip: Your Wickship | Eure Dochtheit | Votre Lumignence | Su Mechencia | Vostra Stoppinenza | Vossa Paviência | 灯心閣下 | 灯芯阁下 |
| Marek: Your Radiance | Eure Strahlkraft | Votre Splendeur | Su Resplandor | Vostro Splendore | Vossa Radiância | まばゆきお方 | 光耀大人 |
| Seren and the herald: lamplighter | {Laternenanzünder\|Laternenanzünderin} | lampiste | {farolero\|farolera} | {lampionaio\|lampionaia} | {acendedor de lampiões\|acendedora de lampiões} | 灯り番 | 点灯人 |
| Seren after day 15: lord | Herr | {monseigneur\|madame} | {señor\|señora} | {signore\|signora} | {senhor\|senhora} | 城主様 | 大人 |
| Dame Orla: young Taper | {junger\|junge} Taper | jeune Taper | joven Taper | giovane Taper | jovem Taper | 若きテイパー | 小泰珀 |
| Tamsin, forgetting herself: {lord} (the name) | {lord} | {lord} | {lord} | {lord} | {lord} | {lord} (bare) | {lord} (bare) |
| Odile, formally: {Lord\|Lady} {lord} | {Burgherr\|Burgherrin} {lord} | {Seigneur\|Dame} {lord} | {lord\|lady} {lord} | {Lord\|Lady} {lord} | {Lorde\|Lady} {lord} | {lord}様 | {lord}大人 |
| Hild Varn (the old friends): {Lord\|Lady} Lantern | {Burgherr\|Burgherrin} | {monseigneur\|madame} | {mi señor\|mi señora} | {mio signore\|mia signora} | {meu senhor\|minha senhora} | 城主様 | 城主大人 |
| The outsiders (Ansel Quay, Ebba Calder, Lorenz Pell): {Lord\|Lady} Lantern | {Lord\|Lady} Lantern | {seigneur\|dame} Lantern | {lord\|lady} Lantern | {Lord\|Lady} Lantern | {Lorde\|Lady} Lantern | ランタン様 | 兰腾大人 |
| Ansel Quay: {Lord\|Lady} {lord} | {Lord\|Lady} {lord} | {seigneur\|dame} {lord} | {lord\|lady} {lord} | {Lord\|Lady} {lord} | {Lorde\|Lady} {lord} | {lord}様 | {lord}大人 |
| The envoys of their own liege: my lady (Lady Maris Brine, Lady Petra Oxmoor) | meine Herrin | ma dame | mi señora | la mia signora | minha senhora | 我が主 | 我家主人 |
| The town calling the lord by trade | lamplighter | lampiste | farolero / farolera | lampionaio / lampionaia | acendedor / acendedora de lampiões | 灯り番 | 点灯人 |

Titles at the start of a sentence take a capital; inside a sentence follow section 6, "Titles".

---

## 5. Each voice in Japanese and Chinese

The Romance languages carry the voices in word choice and sentence length; Japanese and Chinese also carry them in
the speech style. Fixed:

| Speaker | ja: first person, style | zh-Hans: first person, style |
|---|---|---|
| The lord (choice labels) | 私; plain form, short: 「門を開けよう」「まず灯りだ。壁はその後」「もう一度数えてくれ」. Never 〜じゃ, 〜であるぞ, 〜しろ, 〜だぜ | 我; short, plain spoken: "开门。" "先点灯，再修墙。" "再数一遍。" |
| Odile (chancellor) | 私（わたくし）; crisp keigo, です・ます, dry understatement | 我; terse, slightly bookish (书面语), dry |
| Brannock (captain) | 私; short sentences, です・ます clipped, no flourish | 我; very short sentences, soldier's plainness |
| Pip (fool) | わたくしめ; mock-humble keigo turned sideways (〜でございますとも) | 小的 (the fool's mock-humble "I"); playful |
| Mother Hesper (priestess) | 私; calm, slow, polite (〜なさい, 〜でしょう), faintly ominous | 我; calm, slightly classical (之, 其 now and then) |
| Tamsin (cook) | あたし; warm, colloquial-polite (〜ですよ, 〜でしょうに) | 我; warm household speech, no dialect |
| Bram (smith) | 私 when unavoidable; fragments, polite ending only where a verb ends the sentence | 我; fragments of two or three words |
| Marek (merchant) | わたくし; oily merchant keigo (〜でございます, 〜いたします) | 鄙人; flowery, flattering, smooth |
| Seren | 私; quiet, distant です・ます, few words | 我; sparse, distant |
| Ser Ludo (knight) | わたくし; grand and sincere (〜ですぞ, 〜いたしましょう!) | 本骑士; grand, sincere, a little old-fashioned |
| Finch (bard) | 私; theatrical polite | 我; theatrical |
| The herald | わたくし (rare); archaic court courtesy (〜でございましょう), cold; the King is 我が王 or 王 | 我 (rare); formal, faintly classical; the King is 吾王; never 汝 |
| Ansel Quay (envoy) | 私; courteous, tired keigo | 我; courteous, tired |
| Lorenz Pell (steward) | わたくし; smooth keigo, a velvet glove | 我; smooth, polished |
| Hild Varn | 私; blunt です・ます | 我; blunt, direct |
| Ebba Calder (auditor) | 私; precise です・ます | 我; precise, clipped |
| Dame Orla Lorn | わたし; plain form, old and unafraid (〜だよ, 〜ね), never 〜じゃ | 我; plain, commanding, uses 你 |
| Townsfolk, refugees, soldiers | 私 / おれ only for a rough soldier; plain-polite です・ます, simple words, **no dialect** | 我; plain spoken, no dialect |
| Children | ぼく / わたし by the child's look, else none; simple plain form | 我; simple words |
| Narrator (reactions, endings, remembered lines) | だ・である style, present tense as in English, past where the English is past | plain written narration; 你 for the lord |

---

## 6. Fixed terms

German is given for reference (from the catalog; "–" where the German has not used the term yet).

### The world

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| the Worldwall | die Weltmauer | le Mur du Monde | el Muro del Mundo | il Muro del Mondo | o Muro do Mundo | 世界の壁 | 世界之壁 |
| the Wall (short for it) | die Mauer | le Mur | el Muro | il Muro | o Muro | 大壁 | 巨壁 |
| the Cleft | der Spalt | la Faille | la Grieta | la Fenditura | a Fenda | 裂け目 | 裂隙 |
| the Throat | der Schlund | la Gorge | la Garganta | la Gola | a Garganta | 喉谷 | 喉谷 |
| the Throat gate | das Schlundtor | la porte de la Gorge | la puerta de la Garganta | la porta della Gola | o portão da Garganta | 喉谷の門 | 喉谷门 |
| the Throat's mouth | die Mündung des Schlunds | la bouche de la Gorge | la boca de la Garganta | la bocca della Gola | a boca da Garganta | 喉谷の口 | 喉谷口 |
| the Throat's floor | der Grund des Schlunds | le fond de la Gorge | el fondo de la Garganta | il fondo della Gola | o fundo da Garganta | 喉谷の底 | 喉谷底 |
| the shadow land | das Schattenland | le pays d’ombre | la tierra de sombra | la terra d’ombra | a terra das sombras | 影の国 | 影之国 |
| the Gloom | die Düsternis | la Pénombre | la Penumbra | la Penombra | a Penumbra | 宵闇 | 暗霭 |
| the Morninglands | die Morgenlande | les Terres du Matin | las Tierras del Alba | le Terre del Mattino | as Terras da Manhã | 朝の国々 | 晨曦诸国 |
| the valley (Wenddale) | das Tal | la vallée | el valle | la valle | o vale | 谷 | 河谷 |
| the town (Tallowford) | die Stadt | la ville | el pueblo | il borgo | a cidade | 町 | 小镇 (in town: 镇上) |
| the coast | die Küste | la côte | la costa | la costa | a costa | 沿岸 | 海岸 |
| the lake towns | die Seestädte | les villes du lac | los pueblos del lago | le città del lago | as cidades do lago | 湖の町々 | 湖畔诸镇 |
| the moor road | die Moorstraße | la route de la lande | el camino del páramo | la strada della brughiera | a estrada da charneca | 荒野の道 | 荒原之路 |
| the statues (of the dead lords) | die Statuen | les statues | las estatuas | le statue | as estátuas | 石像 | 石像 |
| fog | Nebel | brouillard | niebla | nebbia | névoa | 霧 | 雾 |

Notes: "Mur / Muro" and 壁 are deliberate: the Worldwall is a mountain range, never a built wall, so no muraille,
muralla, mura or 墙 for it (castle walls are built and take those words, below). The Gorge, Garganta and Gola mean
both throat and gorge. 喉谷 is always the full compound; 谷 alone is the green valley in Japanese.

### House Lantern and its customs

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| House Lantern | Haus Lantern | la maison Lantern | la Casa Lantern | Casa Lantern | a Casa Lantern | ランタン家 | 兰腾家 |
| (any house: House Varn …) | Haus Varn | la maison Varn | la Casa Varn | Casa Varn | a Casa Varn | ヴァーン家 | 瓦恩家 |
| Lanternhold (the castle's name) | Lanternhold | Lanternhold | Lanternhold | Lanternhold | Lanternhold | ランタンホールド | 兰腾堡 |
| the castle | die Burg | le château | el castillo | il castello | o castelo | 城 | 城堡 |
| the Flame (the holy hearth fire) | die Flamme | la Flamme | la Llama | la Fiamma | a Chama | 炎 | 圣焰 |
| the hearth, the hearth fire | der Herd, das Herdfeuer | l’âtre, le feu de l’âtre | el hogar, el fuego del hogar | il focolare, il fuoco del focolare | a lareira, o fogo da lareira | 炉, 炉の火 | 炉, 炉火 |
| the Great Beacon | das Große Leuchtfeuer | le Grand Fanal | la Gran Almenara | il Grande Faro | o Grande Farol | 大烽火 | 大烽火 |
| the beacon (short) | das Leuchtfeuer | le fanal | la almenara | il faro | o farol | 烽火 | 烽火 |
| the beacon tower | der Turm des Leuchtfeuers | la tour du fanal | la torre de la almenara | la torre del faro | a torre do farol | 烽火台 | 烽火台 |
| footing, tower, bowl (its stages) | Fundament, Turm, Schale | fondations, tour, vasque | cimientos, torre, cuenco | fondamenta, torre, coppa | alicerce, torre, bacia | 土台、塔、火皿 | 地基、塔身、火钵 |
| the lighthouse (Saltgate's) | der Leuchtturm | le phare | el faro | il faro | o farol | 灯台 | 灯塔 |
| the Lamp Tithe | der Lichtzehnt | la Dîme de lumière | el Diezmo de la Luz | la Decima della Luce | o Dízimo da Luz | 灯火の貢ぎ | 灯火贡赋 |
| tithe, tithe rolls | Zehnt, Zehntrollen | dîme, rôles de la dîme | diezmo, registros del diezmo | decima, registri della decima | dízimo, registros do dízimo | 貢ぎ, 貢ぎの記録 | 贡赋, 贡赋册 |
| the Count (the custom) | die Zählung | le Compte | el Recuento | la Conta | a Contagem | 灯数え | 数灯 |
| a numbered lantern | eine nummerierte Laterne | une lanterne numérotée | un farol numerado | una lanterna numerata | uma lanterna numerada | 番号つきのランタン | 编号提灯 |
| the empty hook (in the chapel) | der leere Haken | le crochet vide | el gancho vacío | il gancio vuoto | o gancho vazio | 空いた鉤 | 空钩 |
| the Returned | die Heimgekehrten | les Revenants | los Retornados | i Ritornati | os Retornados | 戻り人 | 归来者 |
| the Round (lighting every lamp at dusk) | die Runde | la Ronde | la Ronda | la Ronda | a Ronda | 灯巡り | 巡灯 |
| the horn | das Horn | le cor | el cuerno | il corno | a trompa | 角笛 | 号角 |
| the circlet | der Stirnreif | le cercle | el aro | il cerchio | o aro | 額輪 | 额环 |
| the throne (the lord's chair) | der Thron | le trône | el trono | il trono | o trono | 城主の座 | 主座 |
| the great hall | der Saal | la grande salle | el gran salón | il salone | o salão | 大広間 | 大厅 |
| the chapel | die Kapelle | la chapelle | la capilla | la cappella | a capela | 礼拝堂 | 礼拜堂 |
| the keep | der Bergfried | le donjon | la torre del homenaje | il mastio | a torre de menagem | 主塔 | 主堡 |
| the courtyard | der Burghof | la cour | el patio de armas | il cortile | o pátio | 中庭 | 庭院 |
| the family book | das Familienbuch | le livre de famille | el libro de familia | il libro di famiglia | o livro da família | 家系の書 | 家谱 |
| the Chronicle | die Chronik | la Chronique | la Crónica | la Cronaca | a Crônica | 年代記 | 编年史 |
| the Long Watch (the endless mode) | die Lange Wacht | la Longue Veille | la Larga Vigilia | la Lunga Veglia | a Longa Vigília | 長き見張り | 漫长守望 |
| a lord's watch ("in Lady Ysmay's watch") | Wacht | la veille | la vigilia | la veglia | a vigília | 〜様の代 | 〜大人守城之时 |
| the vigil (Hesper's) | die Wache | la veillée | la vela | la veglia | a vigília | 夜通しの祈り | 守夜 |
| the Night of Lanterns | die Nacht der Laternen | la Nuit des lanternes | la Noche de los Faroles | la Notte delle Lanterne | a Noite das Lanternas | ランタンの夜 | 提灯之夜 |
| the Feast of the Long Watch | das Fest der Langen Wacht | la fête de la Longue Veille | la fiesta de la Larga Vigilia | la festa della Lunga Veglia | a festa da Longa Vigília | 長き見張りの祭り | 守望节 |
| the Dark Year | das Dunkle Jahr | l’Année noire | el Año Oscuro | l’Anno Oscuro | o Ano Escuro | 闇の年 | 黑暗之年 |
| the Kindling (the house's year 1) | – | le Premier Feu | el Primer Fuego | il Primo Fuoco | o Primeiro Fogo | 最初の火 | 初火 |
| Saint Taper | Sankt Taper, der heilige Taper | saint Taper | san Taper | san Taper | são Taper | 聖テイパー | 圣泰珀 |
| the house's words: "Keep the light." | – | « Gardez la lumière. » | «Guarda la luz.» | «Custodisci la luce.» | “Guarde a luz.” | 「灯を守れ」 | “守护灯火。” |
| the half sun (the old arms) | die halbe Sonne | le demi-soleil | el medio sol | il mezzo sole | o meio sol | 半分の太陽 | 半轮太阳 |
| teal and gold (the colours) | blaugrün und gold | bleu canard et or | verde azulado y oro | verde petrolio e oro | verde-azulado e dourado | 青緑と金 | 青绿与金 |
| the lamplighter | der Laternenanzünder, die -in | le / la lampiste | el farolero, la farolera | il lampionaio, la lampionaia | o acendedor, a acendedora de lampiões | 灯り番 | 点灯人 |
| a lantern (the object) | eine Laterne | une lanterne | un farol | una lanterna | uma lanterna | ランタン | 提灯 (festival lanterns: 灯笼) |
| the hooked lantern pole, wick pole | die Laternenstange | la perche à crochet | la pértiga de gancho | la pertica a gancio | a vara de gancho | 鉤竿 | 钩竿 |
| the lamp-runner (Lorn's great-grandchild) | das Lampenkind | le petit porte-lampe | el recadero de las lámparas | il piccolo portalampade | o pequeno carregador de lampiões | 灯り運びの子 | 送灯的孩子 |
| wick | Docht | mèche | mecha | stoppino | pavio | 灯心 | 灯芯 |

Notes: 炎 (ja) and 圣焰 (zh-Hans) are kept for the Flame alone; every other fire is 火. "lampiste" is the French lamplighter and also the lowest man on the ladder ("c’est toujours le lampiste qui
trinque"); that second sense is exactly how Seren and the herald mean it, and the word is the same for both sexes.
Never "allumeur / allumeuse" (the feminine is slang). Italian and Portuguese "faro / farol" serve both the beacon and
Saltgate's lighthouse; the beacon is always "il Grande Faro / o Grande Farol" or "il faro / o farol" of the castle,
the lighthouse is always named with Saltgate or "our", so the reader is never lost. In Japanese the house and the
object share ランタン, as they share "Lantern" in English.

### Titles

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| Burgherr / Burgherrin (the office, as a noun: "the new lord") | der Burgherr, die Burgherrin | le seigneur, la dame | el señor, la señora | il signore, la signora | o senhor, a senhora | 城主 | 城主 |
| House Lantern's own lords before a name (Lord Aldric, Lady Oriel) | Burgherr Aldric, Burgherrin Oriel | le seigneur Aldric, dame Oriel | lord Aldric, lady Oriel | Lord Aldric, Lady Oriel | Lorde Aldric, Lady Oriel | in speech アルドリック様; in narration 城主アルドリック | in speech 奥德里克大人; in narration 城主奥德里克 |
| Other houses' lords (Lord Varn, Lady Petra Oxmoor) | Lord Varn, Lady Petra Oxmoor | le seigneur Varn, dame Petra Oxmoor | lord Varn, lady Petra Oxmoor | Lord Varn, Lady Petra Oxmoor | Lorde Varn, Lady Petra Oxmoor | ヴァーン様, ペトラ・オクスムーア様 | 瓦恩大人, 佩特拉·奥克斯穆尔大人 |
| Ser (Ser Ludo, Ser Aubrey) | Ser Ludo | Ser Ludo | Ser Ludo | Ser Ludo | Ser Ludo | サー・ルド | 卢多爵士 |
| Dame (Dame Orla Lorn) | Dame Orla Lorn | Dame Orla Lorn | Dame Orla Lorn | Dame Orla Lorn | Dame Orla Lorn | デイム・オーラ・ロルン | 奥拉·洛恩女爵 |
| Mother (Mother Hesper) | Mutter Hesper | Mère Hesper | Madre Hesper | Madre Hesper | Madre Hesper | マザー・ヘスパー | 赫斯珀嬷嬷 |
| Captain (Captain Brannock) | Hauptmann Brannock | le capitaine Brannock | el capitán Brannock | il capitano Brannock | o capitão Brannock | ブラノック隊長 | 布兰诺克队长 |
| Steward (Lorenz Pell) | Verwalter | intendant | mayordomo | intendente | intendente | 執事 | 管家 |
| Auditor (Ebba Calder) | Prüferin | contrôleuse | auditora | revisora | auditora | 監査役 | 审计官 |
| Minister of Jokes (Pip's office) | Minister für Witze | ministre des Blagues | ministro de Chistes | ministro delle Battute | ministro das Piadas | 冗談大臣 | 笑话大臣 |
| old Hemmet | der alte Hemmet | le vieux Hemmet | el viejo Hemmet | il vecchio Hemmet | o velho Hemmet | ヘメット爺さん | 老赫米特 |

Capitals: French and Spanish write a title before a name in lower case inside a sentence (le seigneur Aldric, dame
Oriel, lord Varn, lady Oriel, el capitán Brannock); Italian and Portuguese capitalise Lord, Lady and Lorde. "Ser
Ludo", "Dame Orla" and "Mother / Mère / Madre Hesper" are name forms and keep their capital everywhere.

### The court and the speakers (the cards' names and roles)

Names stay as in English in the Latin-script languages; ja and zh-Hans as in section 7.

| English role | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| Chancellor (Odile) | Kanzlerin | Chancelière | Canciller | Cancelliera | Chanceler | 家宰 | 家宰 |
| Captain of the guard (Brannock) | Hauptmann der Wache | Capitaine de la garde | Capitán de la guardia | Capitano della guardia | Capitão da guarda | 衛兵隊長 | 卫队长 |
| Fool (Pip) | Narr | Bouffon | Bufón | Giullare | Bobo da corte | 道化 | 弄臣 |
| Priestess of the Flame (Mother Hesper) | Priesterin der Flamme | Prêtresse de la Flamme | Sacerdotisa de la Llama | Sacerdotessa della Fiamma | Sacerdotisa da Chama | 炎の司祭 | 圣焰女祭司 |
| Cook (Tamsin) | Köchin | Cuisinière | Cocinera | Cuoca | Cozinheira | 料理番 | 厨娘 |
| Smith (Bram) | Schmied | Forgeron | Herrero | Fabbro | Ferreiro | 鍛冶屋 | 铁匠 |
| Travelling merchant (Marek) | Fahrender Händler | Marchand ambulant | Mercader ambulante | Mercante girovago | Mercador ambulante | 行商人 | 行商 |
| Bearer of the grey lantern (Seren) | Trägerin der grauen Laterne | Porteuse de la lanterne grise | Portadora del farol gris | Portatrice della lanterna grigia | Portadora da lanterna cinzenta | 灰色のランタンを持つ者 | 提灰灯的人 |
| The Stranger (Seren unrevealed; a woman, as the German says) | Die Fremde | L’Étrangère | La Forastera | La Straniera | A Forasteira | 見知らぬ女 | 陌生女子 |
| Wandering knight (Ser Ludo) | Fahrender Ritter | Chevalier errant | Caballero andante | Cavaliere errante | Cavaleiro andante | 遍歴の騎士 | 游侠骑士 |
| Wandering bard (Finch) | Fahrender Barde | Barde errant | Bardo errante | Bardo errante | Bardo errante | 吟遊詩人 | 吟游诗人 |
| Envoy of House Brine (Ansel Quay) | Gesandter des Hauses Brine | Envoyé de la maison Brine | Enviado de la Casa Brine | Inviato di Casa Brine | Enviado da Casa Brine | ブライン家の使節 | 布赖恩家的使节 |
| Herald of the Lightless King | Herold des Lichtlosen Königs | Héraut du Roi sans lumière | Heraldo del Rey sin Luz | Araldo del Re senza Luce | Arauto do Rei sem Luz | 光なき王の伝令 | 无光之王的传令官 |
| Daughter of House Varn (Hild Varn) | Tochter des Hauses Varn | Fille de la maison Varn | Hija de la Casa Varn | Figlia di Casa Varn | Filha da Casa Varn | ヴァーン家の娘 | 瓦恩家之女 |
| Steward of House Oxmoor (Lorenz Pell) | Verwalter des Hauses Oxmoor | Intendant de la maison Oxmoor | Mayordomo de la Casa Oxmoor | Intendente di Casa Oxmoor | Intendente da Casa Oxmoor | オクスムーア家の執事 | 奥克斯穆尔家的管家 |
| Auditor of Stillmere (Ebba Calder) | Prüferin aus Stillmere | Contrôleuse de Stillmere | Auditora de Stillmere | Revisora di Stillmere | Auditora de Stillmere | スティルミアの監査役 | 斯蒂尔米尔审计官 |
| House Lorn of Greybell (Dame Orla) | Haus Lorn von Greybell | Maison Lorn de Greybell | Casa Lorn de Greybell | Casa Lorn di Greybell | Casa Lorn de Greybell | グレイベルのロルン家 | 格雷贝尔的洛恩家 |
| Builder | Handwerker | Bâtisseur | Albañil | Muratore | Pedreiro | 職人 | 工匠 |
| Child | Kind | Enfant | Niño | Bambino | Criança | 子ども | 孩子 |
| Farmer | Bauer | Paysan | Campesino | Contadino | Camponês | 農夫 | 农夫 |
| Farmer's wife | Bäuerin | Paysanne | Campesina | Contadina | Camponesa | 農婦 | 农妇 |
| Merchant | Händler | Marchand | Mercader | Mercante | Mercador | 商人 | 商人 |
| Noble | Edelmann | Noble | Noble | Nobile | Nobre | 貴族 | 贵族 |
| Refugee | Flüchtling | Réfugié | Refugiado | Profugo | Refugiado | 避難民 | 难民 |
| Soldier | Soldat | Soldat | Soldado | Soldato | Soldado | 兵士 | 士兵 |
| Townsman | Bürger | Habitant | Vecino | Cittadino | Morador | 町の男 | 镇民 |
| Townswoman | Bürgerin | Habitante | Vecina | Cittadina | Moradora | 町の女 | 镇上妇人 |
| Widow | Witwe | Veuve | Viuda | Vedova | Viúva | 未亡人 | 寡妇 |

### The houses of the Morninglands

| House, seat | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| House Lantern (the Cleft) | Haus Lantern | la maison Lantern | la Casa Lantern | Casa Lantern | a Casa Lantern | ランタン家 | 兰腾家 |
| House Varn of Highcairn | Haus Varn von Highcairn | la maison Varn de Highcairn | la Casa Varn de Highcairn | Casa Varn di Highcairn | a Casa Varn de Highcairn | ハイケアンのヴァーン家 | 海凯恩的瓦恩家 |
| House Brine of Saltgate | Haus Brine von Saltgate | la maison Brine de Saltgate | la Casa Brine de Saltgate | Casa Brine di Saltgate | a Casa Brine de Saltgate | ソルトゲートのブライン家 | 索尔特盖特的布赖恩家 |
| House Oxmoor of Goldenacre | Haus Oxmoor von Goldenacre | la maison Oxmoor de Goldenacre | la Casa Oxmoor de Goldenacre | Casa Oxmoor di Goldenacre | a Casa Oxmoor de Goldenacre | ゴールデンエーカーのオクスムーア家 | 戈尔登埃克的奥克斯穆尔家 |
| House Calder of Stillmere | Haus Calder von Stillmere | la maison Calder de Stillmere | la Casa Calder de Stillmere | Casa Calder di Stillmere | a Casa Calder de Stillmere | スティルミアのコールダー家 | 斯蒂尔米尔的考尔德家 |
| House Lorn of Greybell | Haus Lorn von Greybell | la maison Lorn de Greybell | la Casa Lorn de Greybell | Casa Lorn di Greybell | a Casa Lorn de Greybell | グレイベルのロルン家 | 格雷贝尔的洛恩家 |

### The creatures of the Gloom

| English (short form) | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| sootling | Rußling | fumeron | hollinejo | fuligginello | fuliginho | 煤影 | 煤影 |
| shadehound (hound) | Schattenhund (Hund) | chien d’ombre (chien) | sabueso de sombra (sabueso) | segugio d’ombra (segugio) | cão de sombra (cão) | 影犬 | 影犬 |
| soot crow (crow) | Rußkrähe (Krähe) | corneille de suie (corneille) | cuervo de hollín (cuervo) | cornacchia di fuliggine (cornacchia) | corvo de fuligem (corvo) | 煤烏 (烏) | 煤鸦 (鸦) |
| ash brute (brute) | Unhold | brute de cendre (brute) | bestia de ceniza (bestia) | bruto di cenere (bruto) | brutamontes de cinza (brutamontes) | 灰鬼 | 灰蛮 |
| gloomweaver | – | tisse-pénombre | tejepenumbra | tessipenombra | tecelão da penumbra | 宵闇織り | 暗霭织者 |
| the Ash Giant | der Riese | le Géant de cendre | el Gigante de Ceniza | il Gigante di Cenere | o Gigante de Cinzas | 灰の巨人 | 灰烬巨人 |
| the Lightless King | der Lichtlose König | le Roi sans lumière | el Rey sin Luz | il Re senza Luce | o Rei sem Luz | 光なき王 | 无光之王 |
| the King beneath the Gloom (the herald's phrase) | der König unter der Düsternis | le Roi sous la Pénombre | el Rey bajo la Penumbra | il Re sotto la Penombra | o Rei sob a Penumbra | 宵闇の下の王 | 暗霭之下的王 |
| the herald | der Herold | le héraut | el heraldo | l’araldo | o arauto | 伝令 | 传令官 |
| his crown, mantle, snuffer | Krone, Mantel, Löscher | couronne, manteau, éteignoir | corona, manto, apagavelas | corona, manto, spegnitoio | coroa, manto, apagador de velas | 冠, 外套, 灯消し | 王冠, 斗篷, 熄灯罩 |
| the creatures, the figures (generic) | die Kreaturen, die Gestalten | les créatures, les silhouettes | las criaturas, las figuras | le creature, le figure | as criaturas, as figuras | 影の者たち | 影人 |

Note: "the weavers" of the market petitions are human cloth-weavers (tisserands, tejedores, tessitori, tecelões,
機織り, 织工), never gloomweavers. The creatures keep the plain plural of their name; they are never "demons",
"monsters" in a cheap sense, "goblins" or "ghosts".

### Defences and soldiers in the story texts

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| the outer line | die äußere Linie | la ligne extérieure | la línea exterior | la linea esterna | a linha externa | 外の防衛線 | 外防线 |
| the middle line | die mittlere Linie | la ligne du milieu | la línea central | la linea di mezzo | a linha do meio | 中の防衛線 | 中防线 |
| the walls (built, of the castle) | die Mauern | les murailles | las murallas | le mura | as muralhas | 城壁 | 城墙 |
| the gatehouse | das Torhaus | le châtelet | la torre de entrada | il torrione d’ingresso | a torre do portão | 門楼 | 门楼 |
| the portcullis | das Fallgitter | la herse | el rastrillo | la saracinesca | a grade levadiça | 落とし格子 | 吊闸 |
| the wall walk | der Wehrgang | le chemin de ronde | el adarve | il cammino di ronda | o adarve | 城壁の歩廊 | 城墙步道 |
| tower, watchtower | Turm, Wachturm | tour, tour de guet | torre, atalaya | torre, torre di guardia | torre, torre de vigia | 塔, 物見櫓 | 塔, 瞭望塔 |
| brazier | Feuerschale | brasero | brasero | braciere | braseiro | 篝火 | 火盆 |
| stake pit | Pfahlgrube | fosse à pieux | foso de estacas | fossa a pali | fosso de estacas | 杭穴 | 尖桩坑 |
| pitch | Pech | poix | brea | pece | piche | 瀝青 | 沥青 |
| archers | Bogenschützen | archers | arqueros | arcieri | arqueiros | 弓兵 | 弓手 |
| guards | Wachen | gardes | guardias | guardie | guardas | 衛兵 | 卫兵 |
| builders | Bauleute, Handwerker | bâtisseurs | albañiles | muratori | pedreiros | 職人 | 工匠 |
| fire arrows | Brandpfeile | flèches enflammées | flechas incendiarias | frecce incendiarie | flechas incendiárias | 火矢 | 火矢 |
| the lads (Brannock's men) | die Jungs | les gars | los muchachos | i ragazzi | os rapazes | 若い連中 | 弟兄们 |
| the scouts, the lookout | die Späher, der Ausguck | les éclaireurs, la vigie | los exploradores, el vigía | gli esploratori, la vedetta | os batedores, o vigia | 斥候, 見張り | 斥候, 瞭望哨 |

### Smaller words that recur

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| audience (at the throne) | Audienz | audience | audiencia | udienza | audiência | 謁見 | 接见 |
| petition, petitioner | Bittgesuch, Bittsteller | requête, requérant | petición, peticionario | supplica, supplicante | petição, peticionário | 陳情, 陳情者 | 请愿, 请愿人 |
| Odile's Counsel (the hint's heading) | Odiles Rat | le conseil d’Odile | el consejo de Odile | il consiglio di Odile | o conselho de Odile | オディールの助言 | 奥黛尔的谏言 |
| the treasury | die Schatzkammer | le trésor | el tesoro | il tesoro | o tesouro | 金庫 | 府库 |
| the ledger | das Kassenbuch | le registre | el libro de cuentas | il libro dei conti | o livro-caixa | 帳簿 | 账簿 |
| the lectern (where taxes are set) | das Pult | le lutrin | el atril | il leggio | o atril | 書見台 | 书案 |
| the herb-wife | die Kräuterfrau | la guérisseuse | la herbolaria | la donna delle erbe | a erveira | 薬草師の女 | 草药婆 |
| dusk, dawn, first light | Dämmerung, Morgengrauen | crépuscule, aube, petit jour | anochecer, alba, primera luz | crepuscolo, alba, prima luce | crepúsculo, alvorada, primeira luz | 日暮れ, 夜明け, 明け方 | 黄昏, 黎明, 破晓 |
| gold, silver, copper (money) | Gold, Silber, Kupfer | pièces d’or, d’argent, un sou | monedas de oro, de plata, un cobre | monete d’oro, d’argento, un soldo | moedas de ouro, de prata, um tostão | 金貨, 銀貨, 銅貨 | 金币, 银币, 铜板 |

### Ser Ludo's boasts (translated, as the German does)

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| Ser Ludo of the Seven Hills | Ser Ludo von den Sieben Hügeln | Ser Ludo des Sept Collines | Ser Ludo de las Siete Colinas | Ser Ludo delle Sette Colline | Ser Ludo das Sete Colinas | 七つ丘のサー・ルド | 七丘的卢多爵士 |
| the Wyrm of Brackwater | der Lindwurm von Brackwasser | la Guivre des Eaux-Saumâtres | la Sierpe de Aguasalobres | il Vermo di Acquasalmastra | a Serpe de Águas Salobras | 汽水沼の大蛇 | 咸水沼的巨蟒 |
| the Great Dragon of the North | der Große Drache des Nordens | le Grand Dragon du Nord | el Gran Dragón del Norte | il Grande Drago del Nord | o Grande Dragão do Norte | 北の大竜 | 北方巨龙 |

---

## 7. Names

**Latin-script languages (fr, es, it, pt-BR):** every name of a person, house or town stays exactly as in English,
with no accent added and no plural ending ("the Brisks" → les Brisk, los Brisk, i Brisk, os Brisk; the German says
"die Brisks", which follows German habit, not ours). Only titles are translated (section 6). The default name of a
lord who types none is "Robin" in every Latin-script language.

**Japanese and Chinese:** every name is transcribed once, here, and never otherwise. Japanese joins the parts of a
name with ・ (U+30FB), Chinese with · (U+00B7). Honorifics follow section 4.

| English | ja | zh-Hans | | English | ja | zh-Hans |
|---|---|---|---|---|---|---|
| Aldric | アルドリック | 奥德里克 | | Ansel Quay | アンセル・キー | 安塞尔·基 |
| Edric | エドリック | 埃德里克 | | Hild Varn | ヒルド・ヴァーン | 希尔德·瓦恩 |
| Oriel | オリエル | 奥丽尔 | | Harrow Varn | ハロウ・ヴァーン | 哈罗·瓦恩 |
| Ysmay | イズメイ | 伊斯梅 | | Maris Brine | マリス・ブライン | 玛丽丝·布赖恩 |
| Corwin | コーウィン | 科温 | | Petra Oxmoor | ペトラ・オクスムーア | 佩特拉·奥克斯穆尔 |
| Taper | テイパー | 泰珀 | | Aubrey Oxmoor | オーブリー・オクスムーア | 奥布里·奥克斯穆尔 |
| Odile | オディール | 奥黛尔 | | Lorenz Pell | ローレンツ・ペル | 洛伦茨·佩尔 |
| Brannock | ブラノック | 布兰诺克 | | Ebba Calder | エッバ・コールダー | 埃芭·考尔德 |
| Pip | ピップ | 皮普 | | Orla Lorn | オーラ・ロルン | 奥拉·洛恩 |
| Hesper | ヘスパー | 赫斯珀 | | Hemmet | ヘメット | 赫米特 |
| Tamsin | タムシン | 塔姆辛 | | Gerald (the sootling) | ジェラルド | 杰拉尔德 |
| Bram | ブラム | 布拉姆 | | the Brisks (family) | ブリスク家 | 布里斯克一家 |
| Marek | マレク | 马雷克 | | Robin (default name) | ロビン | 罗宾 |
| Seren | セレン | 塞伦 | | | | |
| Ludo | ルド | 卢多 | | | | |
| Finch | フィンチ | 芬奇 | | | | |

| Houses and places | ja | zh-Hans | | Houses and places | ja | zh-Hans |
|---|---|---|---|---|---|---|
| Lantern (house) | ランタン | 兰腾 | | Tallowford | タロウフォード | 塔洛福德 |
| Lanternhold | ランタンホールド | 兰腾堡 | | Wenddale | ウェンデイル | 温德代尔 |
| Varn | ヴァーン | 瓦恩 | | the Wend (river) | ウェンド川 | 温德河 |
| Brine | ブライン | 布赖恩 | | Highcairn | ハイケアン | 海凯恩 |
| Oxmoor | オクスムーア | 奥克斯穆尔 | | Saltgate | ソルトゲート | 索尔特盖特 |
| Calder | コールダー | 考尔德 | | Goldenacre | ゴールデンエーカー | 戈尔登埃克 |
| Lorn | ロルン | 洛恩 | | Stillmere | スティルミア | 斯蒂尔米尔 |
| | | | | Greybell | グレイベル | 格雷贝尔 |
| | | | | Beaconfoot | ビーコンフット | 比肯富特 |
| | | | | Chandler's Row (a street) | チャンドラー横丁 | 钱德勒巷 |

Why: Lorn is ロルン, not ローン, which reads as "loan" for a poor, proud house. "Lantern" is 兰腾 in Chinese, a
sound transcription as the rule wants (never 灯笼家); "-hold" becomes 堡 as Chinese does for "-burgh" (爱丁堡), the
one exception. Odile is 奥黛尔 (a woman's name), Gerald 杰拉尔德, Seren 塞伦. The Beaconfoot folk are ビーコンフットの人々,
比肯富特人.

---

## 8. Punctuation and typography

The game's face (IM Fell English) has U+00A0 (no-break space) but **not** U+202F or U+2009 (checked on the font
files); so French uses U+00A0 wherever its typography wants a space that must not break. Japanese is set in Hiragino
Mincho and Chinese in the system serif (UI-look.md "Type"); neither has an italic, so no text relies on italics.
Every language: curly apostrophe ’ (never '), … as one character (never ...), no straight " anywhere, no line breaks,
no double spaces, numbers as in section 10.

| | Quotations | Inside a quotation | Other rules |
|---|---|---|---|
| fr | « » with U+00A0 inside: « Oui. » | “ ” | U+00A0 before ; : ! ? and after « / before »; capitals keep their accents (À, É, Ç); song titles in « » |
| es | «» without spaces | “ ” | every question and exclamation opens with ¿ / ¡ (also mid-sentence: «Y, ¿quién paga?»); song titles in «» |
| it | «» without spaces | “ ” | È, not E’ (and accents on capitals); po’ with ’; song titles in «» |
| pt-BR | “ ” | ‘ ’ | song titles in “ ” |
| ja | 「」 | 『』, also for song titles | full-width 。、！？ (never . , ! ?); after ！ or ？ a full-width space U+3000 when the text goes on, none before 」; …… and ―― always doubled; ・ in names; no spaces; numbers half-width (section 10) |
| zh-Hans | “ ” | ‘ ’ | 《》 for song and book titles; full-width ，。！？：；、 ; …… and —— doubled; · in names; no spaces; numbers half-width (section 10) |

The English quotes speech inside reactions ("“As you say.”") and in choice labels ("“We hold until dawn.”"); every
language keeps that quotation, in its own marks. A spoken quotation ends with its full stop inside the marks where the
language wants it (fr « Comme vous voudrez. », es «Como usted diga.», pt-BR “Como o senhor quiser.”).

---

## 9. When the German decides

The English is the source; the German was written beside it and settles what the English leaves open. Take from the
German, in this order:

1. **Who is male or female** among third persons the English leaves open: the Stranger is a woman (Die Fremde), the
   auditor is a woman (Prüferin), the scribe, the builder, the bard and the herald are men, the lamp-runner and the
   child are left neutral (Lampenkind, Kind). Where your language has no neutral word, use a neutral noun if one
   exists (enfant, criança, 子ども, 孩子) and the masculine generic otherwise (niño, bambino, porte-lampe).
2. **Which word of address belongs to the speaker** (section 4.2): town, soldiers and court differ in German; old
   friends (Hild Varn) use the house's own title, outsiders (Ansel Quay, Ebba Calder, Lorenz Pell) the foreign
   "Lord / Lady".
3. **Which of two readings is meant** when an English word has two: keep (tower or verb), watch (duty, vigil or a
   lord's time), line (a defence line), count (to count or the Count), light (a lamp or daylight), will (future or
   wish). The German chose one; take that one.
4. **Infinitive or order in a choice label.** Where the German writes an infinitive ("Den Pflug segnen", "Das Pech
   kaufen"), the label names an action: use your infinitive (fr Bénir la charrue, es Bendecir el arado, it Benedire
   l'aratro, pt-BR Abençoar o arado, ja 鋤を祝福する, zh-Hans 为犁祝福). Where it writes an order or a sentence
   ("Lasst alle herein", "Ihr bekommt Euren Turm"), the lord speaks to someone: use the order or sentence in the
   register of section 4.
5. **Intimacy.** Where the German switches to "du" (children; Pip's farewell), switch as section 4.1 says.
6. **That a joke is recreated.** Where the German rebuilt a pun or a rhyme instead of translating it, build your
   own in the same spirit and length.

Never take from the German: an added or dropped detail (the German adds dancing to the Feast of the Long Watch; the
English does not have it, so nobody else adds it), German word order, or German compound nouns turned into long
phrases. When the English and the German disagree in substance, follow the English and list the key in the batch
notes.

---

## 10. Numbers, money, time

- **Latin-script languages** spell numbers as the English does: words where the English has words ("Twenty gold" →
  vingt pièces d’or, veinte monedas de oro, venti monete d’oro, vinte moedas de ouro), figures where it has figures.
- **Japanese and Chinese** write amounts the player acts on (gold, people, days, nights, a lantern's number) in
  half-width Arabic figures: 金貨20枚, 20金币, 3日, 41番のランタン, 41号提灯. Round or idiomatic numbers stay in
  characters: 千年, 一千年, 三度, 九百年.
- Money: gold, silver, copper as in section 6 ("Smaller words"). Never a real currency (no euro, peso, real, yen,
  yuan, livre, ducat, florin).
- Times of day by light, not clock, as the English does: at dusk, at dawn, at the horn, at first light.

---

## 11. Names still to come

Not in the catalog yet; fixed now so that the story panels, the chapter end and the endless mode use the same words.

| English | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|
| Chapter 1: The Dark Beacon | Le Fanal éteint | La Almenara Apagada | Il Faro Spento | O Farol Apagado | 消えた烽火 | 熄灭的烽火 |
| The Open Lantern (ending) | La Lanterne ouverte | El Farol Abierto | La Lanterna Aperta | A Lanterna Aberta | 開かれたランタン | 敞开的提灯 |
| The Shuttered Lantern (ending) | La Lanterne close | El Farol Cerrado | La Lanterna Chiusa | A Lanterna Fechada | 閉ざされたランタン | 闭合的提灯 |
| The Guttering Lantern (ending) | La Lanterne vacillante | El Farol Mortecino | La Lanterna Morente | A Lanterna Bruxuleante | 消えかけのランタン | 将熄的提灯 |
| The Long Watch (endless mode) | La Longue Veille | La Larga Vigilia | La Lunga Veglia | A Longa Vigília | 長き見張り | 漫长守望 |
| Lord Lantern / Lady Lantern (the two tiles at a new game; German: Burgherr / Burgherrin) | Seigneur Lantern / Dame Lantern | Lord Lantern / Lady Lantern | Lord Lantern / Lady Lantern | Lorde Lantern / Lady Lantern | 城主 / 女城主 | 城主 / 女城主 |
