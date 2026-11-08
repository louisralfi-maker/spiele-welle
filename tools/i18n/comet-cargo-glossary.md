# Comet Cargo glossary

Use these terms in the app (`games/comet-cargo/Resources/Localizable.xcstrings`, source of truth
`tools/i18n/comet-cargo-pending.py`) and in the store texts (`games/comet-cargo/store/metadata.json`).

| English | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|
| ring (orbit ring) | Ring | anneau | anillo | anello | anel | リング | 环（第4环） |
| Ring 4 | Ring 4 | Anneau 4 | Anillo 4 | Anello 4 | Anel 4 | リング4 | 第4环 |
| ring network | Ringnetz | réseau d'anneaux | red de anillos | rete di anelli | rede de anéis | リング網 | 轨道环网 |
| ring bonus | Ring-Bonus | bonus d'anneau | bonus de anillo | bonus anello | bônus de anel | リングボーナス | 成环奖励 |
| stage (rocket stage) | Stufe | étage | etapa | stadio | estágio | 段 | 级 |
| drop a stage | Stufe abwerfen | larguer l'étage | soltar la etapa | sganciare lo stadio | soltar o estágio | 段を切り離す | 分离火箭级 |
| Drop! (tag) | Abwerfen! | Larguez ! | ¡Suelta! | Sgancia! | Solte! | 分離！ | 分离！ |
| stage drops (results) | Stufentrennungen | Largages | Etapas soltadas | Sganci | Separações | 段の切り離し | 级分离 |
| satellite | Satellit | satellite | satélite | satellite | satélite | 衛星（〜基） | 卫星（〜颗） |
| release a satellite | Satellit aussetzen | libérer un satellite | liberar un satélite | rilasciare un satellite | liberar um satélite | 衛星を放出 | 释放卫星 |
| delivery | Lieferung | livraison | entrega | consegna | entrega | 配送 | 交付 |
| apex | Gipfelhöhe | apogée | apogeo | apogeo | apogeu | 最高点 | 最高点 |
| launch (button) | Starten | Décoller | Despegar | Lancia | Lançar | 発射 | 发射 |
| Tap to launch | Tippen zum Starten | Touchez pour décoller | Toca para despegar | Tocca per lanciare | Toque para lançar | タップで発射 | 点击发射 |
| collect (results button) | Einsammeln | Encaisser | Cobrar | Incassa | Coletar | 受け取る | 领取 |
| coins | Münzen | pièces | monedas | monete | moedas | コイン | 金币 |
| upgrade(s) | Upgrade(s) | amélioration(s) | mejora(s) | potenziamento/i | melhoria(s) | 強化 | 升级 |
| Engines | Triebwerke | Moteurs | Motores | Motori | Motores | エンジン | 发动机 |
| Tanks | Tanks | Réservoirs | Tanques | Serbatoi | Tanques | タンク | 燃料箱 |
| Stages (upgrade) | Stufen | Étages | Etapas | Stadi | Estágios | 段数 | 级数 |
| Cargo bay | Frachtraum | Soute | Bodega | Stiva | Porão de carga | 貨物室 | 货舱 |
| Guidance | Steuerung | Guidage | Guiado | Guida | Navegação | 誘導 | 制导 |
| thrust | Schub | poussée | empuje | spinta | empuxo | 推力 | 推力 |
| fuel | Treibstoff | carburant | combustible | carburante | combustível | 燃料 | 燃料 |
| timing windows | Zeitfenster | marge de timing | margen de tiempo | margine di tempo | margem de tempo | タイミング幅 | 时机窗口 |
| Perfect | Perfekt | Parfait | Perfecto | Perfetto | Perfeito | パーフェクト | 完美 |
| Great | Super | Super | Genial | Ottimo | Ótimo | グレート | 很棒 |
| Good | Gut | Bien | Bien | Buono | Bom | グッド | 不错 |
| Early | Zu früh | Trop tôt | Temprano | Presto | Cedo | 早すぎ | 过早 |
| Late | Zu spät | Trop tard | Tarde | Tardi | Tarde | 遅すぎ | 过晚 |
| Lost | Verloren | Perdu | Perdido | Perso | Perdido | ロスト | 丢失 |
| best (altitude) | Rekord | record | récord | record | recorde | ベスト | 最佳 |
| New best altitude | Neuer Höhenrekord | Nouveau record d'altitude | Nuevo récord de altura | Nuovo record di quota | Novo recorde de altitude | 最高高度を更新 | 刷新高度纪录 |
| last (flight) | Zuletzt | Dernier | Último | Ultimo | Último | 前回 | 上次 |
| next goal | Nächstes Ziel | Objectif | Objetivo | Obiettivo | Objetivo | 次の目標 | 下一目标 |
| flight report | Flugbericht | rapport de vol | informe de vuelo | rapporto di volo | relatório de voo | 飛行レポート | 飞行报告 |

## Style

- Address: German du-less imperatives and infinitives as before; French "vous"; Spanish "tú"; Italian "tu";
  Portuguese (Brazil) "você"; Japanese plain game style; Chinese plain.
- French: no-break space U+00A0 before ":" and narrow no-break space U+202F before "!" and "?".
- Spanish: opening ¡ and ¿.
- Japanese and Chinese: full-width ：！？・ and no spaces inside CJK text; keep the space between a number and "km".
- Rating pop-ups are drawn in capitals (`uppercased()`), so ratings stay one or two short words.
- Counts that can be 1 (`%lld coins`, `%lld left`) carry plural variations; other counts use a neutral "Label: n" form.
- Brand and look: "Comet Cargo" is never translated. No real agencies, rockets or brands.
