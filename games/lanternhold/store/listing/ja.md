# Lanternhold: App Store 掲載情報、日本語 (ja)

Draft for the director (store lane, step store-1, 14.11.2026). The `text` blocks go into App Store Connect as they are.
Lines that start with `[if shipped]` describe parts not in the build yet: cut the line, or delete only the marker once
the part is in. `python3 games/lanternhold/store/tools/check_listing.py ja` counts the limits (keywords in UTF-8
bytes: a kana or kanji is three).

## Name

```text
Lanternhold
```

## Subtitle

```text
昼は城を築き、夜を守り抜け
```

## Promotional text

```text
越えられぬ山の壁に開いた、ただひとつの裂け目を守る二十の夜。昼は城を築いて民の訴えを裁き、夜はかがり火を絶やすな。煙の影たちが恐れるのは、光だけだ。
```

## Description

```text
誰も越えられない山の壁に、ただひとつ開いた裂け目。光を恐れる煙の影たちから、そこを守り抜け。
昼は城壁や塔やかがり火を築き、民の訴えを裁き、町の人々の心をつなぎとめる。
夜の戦いはひとりでに進む。闇とあなたの炉の火のあいだに立つのは、昼に築き、灯したものだけだ。

最後の灯火番
千年のあいだ、ひとつの家が「世界の壁」の裂け目を守り続けてきた。だがこの秋、大烽火が消えた。ふたたび灯しに出たアルドリック卿は、二度と戻らなかった。細い金の額冠を継いだのは、城の明かりを灯してきた若き灯火番――あなただ。城主か女城主かを選んで名を決め、鉤のついた灯し竿を手に、光を守れ。

昼：築き、裁く
・峡谷の底に城壁、門、塔、火鉢を築き、杭の落とし穴を掘り、バリスタと投石機を据えよう。
・弓兵と衛兵を雇い入れよう。谷の町には家、畑、市場、酒場を建てて育てていく。
・大広間に入って玉座に座り、民の声を聞こう。農民、兵士、商人、吟遊詩人、本気で竜退治を語る騎士、ほかの名家からの使者。どの裁きも金貨を払うか得るかし、民の心を動かす。あなたの歩く世界そのものを変える裁きもある。
・税を決めよう。満ち足りた町は税を納めて大きくなり、不満を抱えた町はぼやき出す。
・宮廷の面々と言葉を交わそう。皮肉屋の女尚書、無骨な隊長、冗談で本音を言う道化、どんな噂も知っている料理番、そして灰色のランタンを持つ旅の女。
[if shipped] ・玉座のそばの帳簿が、あなたの裁きとその後の成り行きを記していく。

夜：守り抜く
・光こそが戦いの掟。闇の中の怪物は姿が見えず、素早い。光の中では動きが鈍り、弓兵が狙えるようになり、小さなものは燃え尽きる。
・火矢が夜を裂き、火鉢が光の輪を落とし、城壁はひび割れながらも持ちこたえる。
・群れなす煤の影、跳びかかる影の猟犬、そして灰の巨人まで、七種の怪物が押し寄せる。
・ランタンを手に城壁を歩き、傷んだ壁を繕い、カラスに消された火鉢をふたたび灯そう。
[if shipped] ・ランタンを高く掲げれば、その光に触れたものは闇へと退く。
・怪物が大広間の炉の火にたどり着けば、領地は滅びる。

二十の夜
第1章は二十夜。80を超える訴えと、それぞれに秘密を抱えた宮廷が待っている。大烽火を再建せよ。光なき王に傷を負わせられるのは、その光の中だけだ。
[if shipped] 三つの結末は幻灯の絵で語られ、最後の夜、民の心、そしてひとつの苦い選択によって分かれる。
[if shipped] 章を終えても、あなたの領地は果てしない夜を耐え続ける。
[if shipped] 礼拝堂の「ランタンの卓」から、番号を記したランタンを託して斥候や使者を送り出そう。すべてのランタンが戻るとは限らない。

・やわらかく揺らめく光に照らされたピクセルアート。冷たく青い夜に、温かな炎、霧、雨、火の粉
・昼と夜でおよそ5分。夜明けごとに自動でセーブ
・効果音と振動のみ、音楽なし。お気に入りの音楽を流しながら遊べます
・アカウント不要、アプリ内課金なし
[if shipped] ・日本語、英語、ドイツ語、フランス語、スペイン語、イタリア語、ポルトガル語、中国語に対応
```

## Keywords

```text
ドット絵,籠城戦,中世ファンタジー,防衛ゲーム,シミュレーション,選択肢
```

## What's New (1.0)

```text
Lanternhold、最初のリリースです。第1章、裂け目での二十の夜。光を守れ。
```

## Notes

- Every keyword has three characters or more (Apple: "each greater than two characters"), so two-kanji words such as
  中世 or 防衛 stand only inside longer ones. 98 of the 100 bytes; nothing from the subtitle (城, 築き, 夜, 守り抜け).
- The house's name is not used here: the i18n lane's glossary fixes how "Lantern" is written in Japanese
  (katakana or Latin letters). The text says ひとつの家 instead. Align the other terms with that glossary at the join:
  世界の壁 (the Worldwall), 裂け目 (the Cleft), 大烽火 (the Great Beacon), 光なき王 (the Lightless King), 灰の巨人
  (the Ash Giant), 灯火番 (the lamplighter, neutral for lord and lady), 額冠 (the circlet), 城主 / 女城主.
- 煤の影 for the sootlings, never 子鬼 or 小鬼: the small creatures carry no child or goblin reading (STORY.md,
  Louis' decision 6; DESIGN "Not a copy").
