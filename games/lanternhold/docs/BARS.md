# Louis' two bars of 14.11.2026 (for every builder and every critic)

## 1. The art bar

Louis: "Pixel-Look, aber es sollte wie ein verdammtes Triple-A-Game aussehen, dass man gar nicht sieht, dass es von einer KI gemacht wurde, weil es so gut aussieht."

Check every picture of yours at 400 % and at phone size against this list, and fix what fails before you call it done:

- **One pixel grid.** Every sprite, tile and backdrop at the game's native pixel size. No half pixels, no mixed scales, no smoothed scaling, no blur and no soft edges inside the pixel art (glow, fog and light come from the renderer, never from the sheet).
- **Palette colours only.** The game's fixed palette; no near-duplicate colours, no banding.
- **Clean clusters.** No stray pixels, no noise, no dither mush. Every cluster is placed on purpose.
- **Nothing melted or garbled.** Hands, faces, windows, roof tiles, weapons and ornaments read clean. No fake writing on signs or pages: a sign has a picture or real pixel letters.
- **One light direction per scene,** and the shadows agree with it.
- **Silhouettes.** Every figure reads at phone size. Proportions, outline rule and shading steps are the same across all sheets: a figure from one sheet stands next to a figure from another and both are from the same game.
- **No visible repeats:** no tile seam or repeat inside one screen, no two identical houses side by side.
- **Motion:** no frame pops, no sliding feet, no part that changes shape between frames.

The question: would a working pixel artist spot that a machine made this? If yes, redo it with hand-placed pixels (the python art tools), not with another generation. A generated picture is a sketch at most; what ships is drawn onto the grid.

## 2. The interface bar

Louis: "Will das UI ziemlich minimal, aufgeräumt haben wie bei Kingdom Two Crowns, dass die Steuerung und alles selbsterklärend ist." (That game is the bar for craft and feel only; never copy its look, its coin pouch or any picture of it. DESIGN.md "Not a copy".)

- The world explains itself. Where a person, a thing or a light in the world can show something, there is no label, no prompt, no button and no HUD element for it.
- No permanent HUD. A screenshot of the lord simply walking by day shows no interface at all.
- A number appears only when it changes or when a price is asked, next to the thing it belongs to, and fades.
- A card appears only for words (an audience, the ledger, the dawn report) or a real choice, small and at the thing.
- Whatever can be touched answers a touch with a small motion, so the player learns it by trying.

## 3. The people bar (added 14.11.2026 14:20)

Louis: "Was auch verdammt cool wäre, wenn die Bauern und die Leute, die arbeiten, schon richtig verbraucht sind, vom Leben geprägt. Natürlich ist unser Königreich besser, da sind alle fast gleich, weil wir nie so viel Geld hatten. Alle sind vom Leben geprägt, dann ist es halt cool, wenn es lebensfrohe Kinder gibt oder abgehobene reiche Adelige. Das bringt Charakterwechsel mit rein."

- **Those who work are marked by life.** Farmers, builders, washerwomen, guards, the old: a bent back, a heavy step, weathered skin, patched and faded cloth, and one mark each that tells a life (a limp, a bound hand, an eye lost to the Gloom, a stoop from the hoe, hair gone grey early). Worn, never wretched: they straighten when the lord passes because they choose to.
- **Lanternhold is poor and even.** Nobody here is rich, the house included: the lord's cloak is mended, the banners are old, the hall is mighty in stone and plain in everything else. Cloth is undyed wool, earth, soot and one faded house colour. Nobody in town is drawn finer than their neighbour.
- **Children are the bright thing.** Quick where everyone else is slow: they run, skip, fight with sticks, trail after the lord. The one warm, clean accent in the town's colours belongs to them.
- **The nobles of the inner lands are from another world.** They live safe behind the wall: upright, slow, clean, overdressed, with the only saturated cloth and the only gold thread in the game. A footman carries what they will not; they hold a cloth to the nose and look past people. Never monsters: people who have never seen the dark.
- **The change of character is the point.** In every scene with people a player sees at a glance who has carried what. Put the groups next to each other where you can: a child beside an old farmer, a noble's footman beside a guard.
- **Still one game.** The same grid, palette, outline rule and proportions for everyone (bar 1). The difference is posture, pace, cloth and one tell, never another style.
- **In words too.** Working people speak short and dry; children ask; nobles speak in long polite sentences that say little. In English and in German.
