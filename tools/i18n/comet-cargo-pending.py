#!/usr/bin/env python3
"""Comet Cargo translations (source of truth for tools/i18n/catupd.py).

    python3 tools/i18n/comet-cargo-pending.py > /tmp/pending.json
    python3 tools/i18n/catupd.py games/comet-cargo/Resources/Localizable.xcstrings /tmp/pending.json

French uses a no-break space (U+00A0) before ":" and a narrow no-break space (U+202F) before "!" and "?".
Terms follow tools/i18n/comet-cargo-glossary.md.
"""
import json

N = " "   # before a French colon
NN = " "  # before French ! and ?
LANGS = ["de", "fr", "es", "it", "pt-BR", "ja", "zh-Hans"]


def row(*values, comment=None):
    out = dict(zip(LANGS, values))
    if comment:
        out["comment"] = comment
    return out


T = {
    "%@: maximum": row(
        "%@: voll ausgebaut", f"%@{N}: niveau max", "%@: nivel máximo", "%@: livello massimo", "%@: nível máximo",
        "%@：最大レベル", "%@：已满级",
        comment="VoiceOver label of a maxed upgrade's buy button; %@ is the upgrade name (Engines, Tanks, ...)"),
    "%lld coins": {
        "en": {"one": "%lld coin", "other": "%lld coins"},
        "de": {"one": "%lld Münze", "other": "%lld Münzen"},
        "fr": {"one": "%lld pièce", "other": "%lld pièces"},
        "es": {"one": "%lld moneda", "other": "%lld monedas"},
        "it": {"one": "%lld moneta", "other": "%lld monete"},
        "pt-BR": {"one": "%lld moeda", "other": "%lld moedas"},
        "ja": "%lldコイン",
        "zh-Hans": "%lld金币",
        "comment": "VoiceOver: a coin amount (hangar coins, flight coins, results total)"},
    "%lld km": row("%lld km", "%lld km", "%lld km", "%lld km", "%lld km", "%lld km", "%lld km",
                   comment="An altitude in kilometres"),
    "%lld left": {
        "de": "%lld übrig",
        "fr": {"one": "%lld restant", "other": "%lld restants"},
        "es": {"one": "Queda %lld", "other": "Quedan %lld"},
        "it": {"one": "%lld rimasto", "other": "%lld rimasti"},
        "pt-BR": {"one": "%lld restante", "other": "%lld restantes"},
        "ja": "残り%lld基",
        "zh-Hans": "还剩%lld颗",
        "comment": "VoiceOver value of the release button: satellites still aboard"},
    "%lld of 15 rings complete": row(
        "%lld von 15 Ringen komplett", f"Anneaux complets{N}: %lld sur 15", "Anillos completos: %lld de 15",
        "Anelli completati: %lld su 15", "Anéis completos: %lld de 15", "完成したリング：%lld/15", "已完成%lld/15个环",
        comment="VoiceOver value of the ring network picture"),
    "%lld satellites": row(
        "%lld Satelliten", "%lld satellites", "%lld satélites", "%lld satelliti", "%lld satélites", "衛星%lld基",
        "%lld颗卫星", comment="Cargo bay upgrade effect: satellites per flight (2 or more)"),
    "%lld stages": row(
        "%lld Stufen", "%lld étages", "%lld etapas", "%lld stadi", "%lld estágios", "%lld段", "%lld级",
        comment="Stages upgrade effect: rocket stages (2 or more)"),
    "%lld/15 rings": row(
        "%lld/15 Ringe", "%lld/15 anneaux", "%lld/15 anillos", "%lld/15 anelli", "%lld/15 anéis", "リング%lld/15",
        "%lld/15环", comment="Hangar: completed rings out of 15"),
    "Abort flight": row(
        "Flug abbrechen", "Abandonner le vol", "Abortar vuelo", "Interrompi volo", "Abortar voo", "飛行を中止",
        "中止飞行", comment="Pause sheet button: end the flight without pay"),
    "An aborted flight pays nothing.": row(
        "Ein abgebrochener Flug bringt nichts ein.", "Un vol abandonné ne rapporte rien.",
        "Un vuelo abortado no paga nada.", "Un volo interrotto non paga nulla.", "Um voo abortado não rende nada.",
        "中止した飛行は報酬なしです。", "中止飞行将没有任何收益。", comment="Pause sheet note under Abort flight"),
    "Apex": row(
        "Gipfelhöhe", "Apogée", "Apogeo", "Apogeo", "Apogeu", "最高点", "最高点",
        comment="Highest altitude of the flight (results label; scene label 'Apex ≈ 120 km')"),
    "Best": row("Rekord", "Record", "Récord", "Record", "Recorde", "ベスト", "最佳",
                comment="Flight scene: dashed line at the best apex so far"),
    "Best: %lld km": row(
        "Rekord: %lld km", f"Record{N}: %lld km", "Récord: %lld km", "Record: %lld km", "Recorde: %lld km",
        "ベスト：%lld km", "最佳：%lld km", comment="Hangar: best altitude so far"),
    "Buy %@ for %lld coins": row(
        "%1$@ für %2$lld Münzen kaufen", "Acheter %1$@ pour %2$lld pièces", "Comprar %1$@ por %2$lld monedas",
        "Acquista %1$@ per %2$lld monete", "Comprar %1$@ por %2$lld moedas", "%1$@を%2$lldコインで強化",
        "花%2$lld金币升级%1$@", comment="VoiceOver label of an upgrade's buy button; %1$@ upgrade name, %2$lld price"),
    "Cancel": row("Abbrechen", "Annuler", "Cancelar", "Annulla", "Cancelar", "キャンセル", "取消",
                  comment="Reset confirmation: cancel"),
    "Cargo bay": row("Frachtraum", "Soute", "Bodega", "Stiva", "Porão de carga", "貨物室", "货舱",
                     comment="Upgrade name: more satellites per flight"),
    "Coins, upgrades and the ring network start over. This cannot be undone.": row(
        "Münzen, Upgrades und das Ringnetz beginnen von vorn. Das lässt sich nicht rückgängig machen.",
        "Les pièces, les améliorations et le réseau d'anneaux repartent de zéro. Impossible d'annuler.",
        "Las monedas, las mejoras y la red de anillos empiezan de cero. No se puede deshacer.",
        "Monete, potenziamenti e rete di anelli ripartono da zero. L'operazione non si può annullare.",
        "Moedas, melhorias e a rede de anéis voltam do zero. Isso não pode ser desfeito.",
        "コイン、強化、リング網が最初からになります。元に戻すことはできません。",
        "金币、升级和轨道环网都将从头开始。此操作无法撤销。", comment="Reset confirmation message"),
    "Collect": row("Einsammeln", "Encaisser", "Cobrar", "Incassa", "Coletar", "受け取る", "领取",
                   comment="Results button: take the coins and go back to the hangar"),
    "Deliveries": row("Lieferungen", "Livraisons", "Entregas", "Consegne", "Entregas", "配送", "交付",
                      comment="Results section: satellites released this flight"),
    "Done": row("Fertig", "OK", "Listo", "Fine", "OK", "完了", "完成", comment="Closes the settings sheet"),
    "Drop stage": row(
        "Stufe abwerfen", "Larguer l'étage", "Soltar etapa", "Sgancia stadio", "Soltar estágio", "段を切り離す",
        "分离火箭级", comment="VoiceOver action in flight: drop the burning rocket stage"),
    "Drop!": row("Abwerfen!", f"Larguez{NN}!", "¡Suelta!", "Sgancia!", "Solte!", "分離！", "分离！",
                 comment="Small tag next to the rocket while a stage drop would be Perfect (very short)"),
    "Early": row("Zu früh", "Trop tôt", "Temprano", "Presto", "Cedo", "早すぎ", "过早",
                 comment="Stage drop rating: dropped with fuel left (pop-up in capitals, results chip)"),
    "Engines": row("Triebwerke", "Moteurs", "Motores", "Motori", "Motores", "エンジン", "发动机",
                   comment="Upgrade name: more thrust"),
    "Flight report": row("Flugbericht", "Rapport de vol", "Informe de vuelo", "Rapporto di volo",
                         "Relatório de voo", "飛行レポート", "飞行报告", comment="Results screen title"),
    "Fuel": row("Treibstoff", "Carburant", "Combustible", "Carburante", "Combustível", "燃料", "燃料",
                comment="VoiceOver label of the tank gauge"),
    "Fuel +%@": row("Treibstoff +%@", "Carburant +%@", "Combustible +%@", "Carburante +%@", "Combustível +%@",
                    "燃料+%@", "燃料+%@", comment="Tanks upgrade effect; %@ is a percentage such as 9 %"),
    "Good": row("Gut", "Bien", "Bien", "Buono", "Bom", "グッド", "不错",
                comment="Rating, third best (pop-up in capitals, results chip)"),
    "Great": row("Super", "Super", "Genial", "Ottimo", "Ótimo", "グレート", "很棒",
                 comment="Rating, second best (pop-up in capitals, results chip)"),
    "Guidance": row("Steuerung", "Guidage", "Guiado", "Guida", "Navegação", "誘導", "制导",
                    comment="Upgrade name: wider timing windows"),
    "Haptics": row("Vibration", "Vibrations", "Vibración", "Vibrazione", "Vibração", "振動", "振动",
                   comment="Settings switch"),
    "Last": row("Zuletzt", "Dernier", "Último", "Ultimo", "Último", "前回", "上次",
                comment="Flight scene: dashed line at the last flight's apex"),
    "Late": row("Zu spät", "Trop tard", "Tarde", "Tardi", "Tarde", "遅すぎ", "过晚",
                comment="Stage drop rating: dropped well after burnout (pop-up in capitals, results chip)"),
    "Launch": row("Starten", "Décoller", "Despegar", "Lancia", "Lançar", "発射", "发射",
                  comment="Big hangar button; VoiceOver action on the pad"),
    "Lost": row("Verloren", "Perdu", "Perdido", "Perso", "Perdido", "ロスト", "丢失",
                comment="Release rating: satellite released outside every ring"),
    "Max": row("Max", "Max", "Máx.", "Max", "Máx.", "最大", "满级",
               comment="Upgrade buy button when the upgrade is maxed (short)"),
    "New best altitude": row(
        "Neuer Höhenrekord", "Nouveau record d'altitude", "Nuevo récord de altura", "Nuovo record di quota",
        "Novo recorde de altitude", "最高高度を更新", "刷新高度纪录", comment="Results badge"),
    "Next upgrade: %@": row(
        "Nächstes Upgrade: %@", f"Prochain achat{N}: %@", "Próxima mejora: %@", "Prossimo acquisto: %@",
        "Próxima melhoria: %@", "次の強化：%@", "下一项升级：%@",
        comment="Results: the cheapest upgrade the coins are saving for; %@ is the upgrade name"),
    "Next: Ring %lld · %lld km": row(
        "Nächstes Ziel: Ring %lld · %lld km", f"Objectif{N}: anneau %lld · %lld km", "Objetivo: anillo %lld · %lld km",
        "Obiettivo: anello %lld · %lld km", "Objetivo: anel %lld · %lld km", "次の目標：リング%lld・%lld km",
        "下一目标：第%lld环·%lld km", comment="Hangar: the next ring to reach, its number and altitude"),
    "No deliveries": row("Keine Lieferungen", "Aucune livraison", "Sin entregas", "Nessuna consegna",
                         "Nenhuma entrega", "配送なし", "没有交付", comment="Results: no satellite released"),
    "Outside every ring": row(
        "Außerhalb aller Ringe", "Hors des anneaux", "Fuera de los anillos", "Fuori dagli anelli", "Fora dos anéis",
        "リングの外", "不在任何环内", comment="Results row: a satellite released outside every ring"),
    "Pause": row("Pause", "Pause", "Pausa", "Pausa", "Pausar", "一時停止", "暂停",
                 comment="VoiceOver label of the pause button"),
    "Paused": row("Pausiert", "En pause", "En pausa", "In pausa", "Pausado", "一時停止中", "已暂停",
                  comment="Pause sheet title"),
    "Perfect": row("Perfekt", "Parfait", "Perfecto", "Perfetto", "Perfeito", "パーフェクト", "完美",
                   comment="Best rating (pop-up in capitals, results chip)"),
    "Release now": row("Jetzt aussetzen", "Libérez maintenant", "Libera ahora", "Rilascia ora", "Libere agora",
                       "今すぐ放出", "立即释放", comment="VoiceOver label of the release hint"),
    "Release satellite": row(
        "Satellit aussetzen", "Libérer un satellite", "Liberar satélite", "Rilascia satellite", "Liberar satélite",
        "衛星を放出", "释放卫星", comment="VoiceOver label of the release button"),
    "Reset": row("Zurücksetzen", "Réinitialiser", "Restablecer", "Azzera", "Redefinir", "リセット", "重置",
                 comment="Reset confirmation: the destructive button"),
    "Reset all progress?": row(
        "Gesamten Fortschritt zurücksetzen?", f"Réinitialiser toute la progression{NN}?",
        "¿Restablecer todo el progreso?", "Azzerare tutti i progressi?", "Redefinir todo o progresso?",
        "進行状況をすべてリセットしますか？", "要重置全部进度吗？", comment="Reset confirmation title"),
    "Reset progress": row(
        "Fortschritt zurücksetzen", "Réinitialiser la progression", "Restablecer progreso", "Azzera progressi",
        "Redefinir progresso", "進行状況をリセット", "重置进度", comment="Settings button"),
    "Resume": row("Weiter", "Reprendre", "Continuar", "Riprendi", "Continuar", "再開", "继续",
                  comment="Pause sheet button"),
    "Ring %lld": row("Ring %lld", "Anneau %lld", "Anillo %lld", "Anello %lld", "Anel %lld", "リング%lld",
                     "第%lld环", comment="An orbit ring by number (1 to 15)"),
    "Ring %lld complete": row(
        "Ring %lld komplett", "Anneau %lld complet", "Anillo %lld completo", "Anello %lld completato",
        "Anel %lld completo", "リング%lld完成", "第%lld环已完成", comment="Results badge: all 5 slots of a ring filled"),
    "Ring bonus": row("Ring-Bonus", "Bonus d'anneau", "Bonus de anillo", "Bonus anello", "Bônus de anel",
                      "リングボーナス", "成环奖励", comment="Results row: bonus for completing a ring"),
    "Ring network": row("Ringnetz", "Réseau d'anneaux", "Red de anillos", "Rete di anelli", "Rede de anéis",
                        "リング網", "轨道环网", comment="The 15 rings around the planet and the satellites in them"),
    "Satellites lost: %lld": row(
        "Verlorene Satelliten: %lld", f"Satellites perdus{N}: %lld", "Satélites perdidos: %lld",
        "Satelliti persi: %lld", "Satélites perdidos: %lld", "失った衛星：%lld", "丢失卫星：%lld",
        comment="Results: satellites still aboard at the apex"),
    "Settings": row("Einstellungen", "Réglages", "Ajustes", "Impostazioni", "Ajustes", "設定", "设置",
                    comment="Settings sheet title and gear button label"),
    "Sound": row("Ton", "Son", "Sonido", "Suono", "Som", "サウンド", "音效", comment="Settings switch"),
    "Stage drops": row("Stufentrennungen", "Largages", "Etapas soltadas", "Sganci", "Separações", "段の切り離し",
                       "级分离", comment="Results section: the rating of each stage drop"),
    "Stages": row("Stufen", "Étages", "Etapas", "Stadi", "Estágios", "段数", "级数",
                  comment="Upgrade name: one more rocket stage"),
    "Stages never dropped: %lld": row(
        "Nie abgeworfene Stufen: %lld", f"Étages jamais largués{N}: %lld", "Etapas sin soltar: %lld",
        "Stadi mai sganciati: %lld", "Estágios não soltos: %lld", "切り離さなかった段：%lld", "未分离的级：%lld",
        comment="Results chip: stages that never fired because a spent stage was never dropped"),
    "Tanks": row("Tanks", "Réservoirs", "Tanques", "Serbatoi", "Tanques", "タンク", "燃料箱",
                 comment="Upgrade name: more fuel"),
    "Tap now!": row("Jetzt tippen!", f"Touchez vite{NN}!", "¡Toca ya!", "Tocca ora!", "Toque agora!", "今タップ！",
                    "现在点击！", comment="First-flight hint while a stage drop would be Perfect (short, big type)"),
    "Tap to launch": row(
        "Tippen zum Starten", "Touchez pour décoller", "Toca para despegar", "Tocca per lanciare", "Toque para lançar",
        "タップで発射", "点击发射", comment="On the launch pad, big type"),
    "Thrust +%@": row("Schub +%@", "Poussée +%@", "Empuje +%@", "Spinta +%@", "Empuxo +%@", "推力+%@", "推力+%@",
                      comment="Engines upgrade effect; %@ is a percentage"),
    "Timing windows +%@": row(
        "Zeitfenster +%@", "Marge de timing +%@", "Margen de tiempo +%@", "Margine di tempo +%@",
        "Margem de tempo +%@", "タイミング幅+%@", "时机窗口+%@",
        comment="Guidance upgrade effect: wider Perfect and Great windows; %@ is a percentage"),
    "Total": row("Gesamt", "Total", "Total", "Totale", "Total", "合計", "合计", comment="Results: coins of the flight"),
}

print(json.dumps(T, ensure_ascii=False, indent=1))
