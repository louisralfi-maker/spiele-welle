# Lanternhold: App Store 商店信息，简体中文 (zh-Hans)

Draft for the director (store lane, step store-1, 14.11.2026). The `text` blocks go into App Store Connect as they are.
Lines that start with `[if shipped]` describe parts not in the build yet: cut the line, or delete only the marker once
the part is in. `python3 games/lanternhold/store/tools/check_listing.py zh-Hans` counts the limits (keywords in UTF-8
bytes: a hanzi is three).

## Name

```text
Lanternhold
```

## Subtitle

```text
白昼筑城，长夜坚守
```

## Promotional text

```text
无人能越的群山之墙上只有一道裂隙，你要守住它二十个夜晚。白天筑城、裁决百姓的请愿；夜里让火光长明——烟影唯一畏惧的，就是光。
```

## Description

```text
无人能越的群山之墙上，只有一道裂隙。守住它，抵御畏光的烟影。
白天，修筑城墙、塔楼与火盆，裁决百姓的请愿，让城镇安居乐业。
夜里，战斗自行展开。挡在黑暗与你的炉火之间的，只有你亲手建起、亲手点亮的一切。

最后的掌灯人
一千年来，一个家族世代守护着“世界之墙”上的这道裂隙。今年秋天，大烽火熄灭了。阿尔德里克大人出城重燃烽火，从此再没回来。那顶细细的金色头环传给了城堡里年轻的掌灯人——也就是你。为你的城主取名，选择城主或女城主，握起带钩的灯杆，守住这片光。

白天：建设与裁决
• 在峡谷谷底修建城墙、城门、塔楼和火盆，挖掘尖桩陷坑，架设弩炮和投石机。
• 招募弓箭手和卫兵。在山谷小镇建起房屋、农田、集市和酒馆。
• 走进大厅，登上宝座，倾听百姓的声音：农夫、士兵、商人、吟游诗人、坚信自己屠过龙的骑士，还有其他名门的使者。每个决定都会花费或赚取金币，牵动民心，有些还会改变你脚下的世界。
• 设定税率。安居的城镇照常纳税、日渐兴旺；心怀不满的城镇则怨声四起。
• 与宫廷众人交谈：毒舌的女宰相、粗犷的卫队长、用笑话讲真话的弄臣、无所不知的厨娘，还有一位提着灰色灯笼的陌生女子。
[if shipped] • 宝座旁的账簿会记下你的每一次裁决，以及它们带来的后果。

夜晚：坚守
• 光是战斗的法则。黑暗中的怪物无影无形、行动迅捷；一旦被照亮，它们就会变慢，弓箭手才能瞄准，小怪物还会被烧尽。
• 火焰箭划破夜空，火盆投下一片片光圈，城墙虽有裂痕却依然屹立。
• 七种怪物来袭：成群的煤灰影怪、飞扑的影犬，直到灰烬巨人。
• 提着灯笼巡视城墙，修补受损的墙体，重新点燃被乌鸦扑灭的火盆。
[if shipped] • 高举灯笼，被它照到的怪物都会退回黑暗。
• 一旦怪物抵达大厅里的炉火，领地就会沦陷。

二十个夜晚
第一章共二十夜，有80多个请愿，宫廷里人人都藏着秘密。重建大烽火：只有在它的光芒之中，无光之王才会受伤。
[if shipped] 三种结局以幻灯画面讲述，取决于最后一夜、民心，以及一个艰难的抉择。
[if shipped] 章节结束后，你的领地还将度过无尽的长夜。
[if shipped] 在礼拜堂的“灯笼之桌”前，把编号灯笼交给斥候与使者，派他们出发。并非每一盏灯笼都能回来。

• 柔和灵动的光影下的像素画面：冰冷蓝夜中的温暖火光、雾气、雨水与火星
• 一个昼夜约五分钟，每逢黎明自动存档
• 只有音效和振动，没有音乐，你可以边听自己的音乐边玩
• 无需账号，没有应用内购买
[if shipped] • 支持中文、英语、德语、法语、西班牙语、意大利语、葡萄牙语和日语
```

## Keywords

```text
策略游戏,塔防游戏,中世纪,像素风,城堡建造,黑暗奇幻,守城战,模拟经营
```

## What's New (1.0)

```text
Lanternhold首个版本：第一章，裂隙中的二十个夜晚。守住这片光。
```

## Notes

- Every keyword has three characters or more (Apple: "each greater than two characters"). Nothing from the subtitle
  (白昼, 筑城, 长夜, 坚守). 塔防 is the genre word players search for; the game builds towers and walls against
  waves, so it is honest, and it names no game.
- The house's name is not used here: the i18n lane's glossary fixes how "Lantern" is written in Chinese. The text says
  一个家族 instead. Align the other terms with that glossary at the join: 世界之墙 (the Worldwall), 裂隙 (the Cleft),
  大烽火 (the Great Beacon), 无光之王 (the Lightless King), 灰烬巨人 (the Ash Giant), 掌灯人 (the lamplighter, neutral
  for lord and lady), 金色头环 (the circlet; never 金额环, which reads as 'sum of money'), 城主 / 女城主, 火焰箭 (fire arrows; 火箭 would read as rocket).
- 煤灰影怪 for the sootlings: no child reading (STORY.md, Louis' decision 6).
