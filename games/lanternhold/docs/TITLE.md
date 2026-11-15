# Lanternhold: first light (launch, loading, title) and the end of parchment (15.11.2026, 01:05)

The director wrote this from Louis' words of 15.11.2026. It replaces the title of `docs/UI-look.md` and the map style
(parchment) of every card, and it changes rule 3 of `docs/HUD.md`.

## Louis' words (15.11.2026)

"Was wir auch brauchen, ist ein Ladebildschirm vom Game und halt so ein Startbildschirm. Muss halt verdammt cool
aussehen bzw. extrem schön sein. Und das UI auf den Bildern vorher, glaub, ist noch das alte, sieht verdammt scheiße
aus, das Pergament-Ding."

## The director's decision

- **One shot from the app's icon to the first step.** Launch, loading, title and game are one picture that never
  cuts. The light is the progress bar: the game's third pillar ("light is life") from the first second.
- **No parchment anywhere.** Words stand on night glass (section 4).

## 1. The one shot

1. **Launch** (iOS' static launch screen): the night's darkest colour, and the house's lantern, small and unlit, at
   the screen's centre.
2. **Loading:** the wick catches. The flame and its glow grow with the loading. No bar, no percent, no word, no
   spinner. It shows for at least 1.2 s on the first launch and 0.6 s later, and never longer than the loading needs.
3. **The title:** the glow widens and uncovers the picture from the lantern outward. The loading lantern **is** the
   eternal light on the keep; it never moves. The lettering catches the light last, from its centre outward.
4. **The start:** a touch anywhere. The lord, small on the wall walk, raises his lantern in answer, the camera sinks
   to him, and the game runs. No button. On the first start the picture dims back to the lantern and the prologue's
   first slide opens out of it.
5. **The gear** (the interface kit's) stands small in the top right corner and opens the desk: settings, "A new
   heir", privacy. Nothing else stands on the title.
6. After 3 s without a touch one small line fades in at the bottom centre: "Touch to begin" (bone at 70 %, the
   cards' type). VoiceOver: "Lanternhold. Double tap to begin."
7. Reduce Motion: fades in place of the widening glow and of the camera's sink.

## 2. The title picture

- **What it shows:** the gorge at night, seen from the side as the game is. Left, the Throat with the darkness bank,
  cold, with eye glints. In the middle our wall, the gatehouse and the keep, and on the keep the eternal light, the
  one strong light of the picture. Right, the town's warm windows trailing away toward the continent, and the first
  thin line of dawn on the far horizon. Above, stars and the black teeth of the Weltmauer.
- **It lives:** five layers drift slowly against each other (sky, far peaks, the gorge's rock, castle and town, fog
  and foreground). The fog breathes, the light flickers, windows flicker, two sentries stand, the lord stands on the
  wall with his small lantern.
- **Size:** 437 x 201 game px fill an iPhone 17 Pro at scale 6. Draw 520 px wide, so the drift and wider screens
  have room. The eternal light sits at the screen's centre.
- **Palette:** the world's night palette (`docs/ART-look2.md`). Nothing new but the light's gold.
- **The lettering** LANTERNHOLD is drawn, never set in a font: tall capitals of dark iron with a brass edge. Unlit
  they are almost lost in the sky; lit, each letter has a warm rim on the side that faces the light. At most 60 % of
  the screen's width, in the sky above the keep, never over the light.
- **The bar:** a player would take a screenshot of it. No AI tell: no mushy shapes, no stray pixels, no gradient
  bands, one light logic, clean silhouettes at phone size.

## 3. Waiting inside the game

Every later wait (a save loads, a chapter opens) is the same lantern on the same dark. There is no spinner anywhere.

## 4. Night glass (every card, sheet and plaque)

- **Where:** the audience's letter and its choice plaques, Odile's counsel slip, the dawn report, the horn's ribbon,
  the defeat card, the pause sheet, the consent and every other card. One kit, one place in code.
- **The panel:** the night's navy at about 88 % over the world, drawn on the game's pixel grid as a nine-slice and
  scaled with nearest neighbour. One brass line of 1 game px, set 2 game px inside the edge; the corners are notched
  by 1 game px. No shadow, no gradient, no texture, no wax, no seal.
- **Type:** the cards' present type stays (a pixel type is a question for build 3). Text in bone, names and the
  chosen state in lantern gold, secondary lines in a muted blue-grey. Text on the panel has a contrast of 7:1 or more.
- **A choice plaque:** night glass with the brass line. Pressed, it fills with lantern amber from the left in 0.12 s
  and its text turns dark; one haptic tick.
- **Portraits:** a brass line of 1 game px, no mat.
- **Layout, sizes and words do not change.** It is a new skin, so no lane's screen test moves.

## 5. Builds, lanes and the gate

- **Now:** two Opus agents, each with real pictures at 2622 x 1206 as proof. "First light" paints the title
  picture, the lettering, the loading lantern and the launch image (branch `claude/lh-title`). "Night glass" draws
  the panel kit and shows it on real screenshots: the audience, the dawn report, the pause sheet (branch
  `claude/lh-glass`). The director judges both; then Louis sees them.
- **Build 2 (Monday 16.11.2026):** night glass, as part of stage-3-interface or at the join. The launch image and
  the loading lantern. The title, if its picture has passed the director by Sunday noon; one agent wires it after
  the join.
- **If the title is at risk, cut in this order:** the camera's sink (then a fade of 0.4 s through the glow); the
  lettering's light from the centre outward (then all at once); the drift. If the picture itself has not passed,
  build 2 opens on the lantern and the lettering alone, and the picture comes with build 3.
- **Gate.** The player critic, at phone size: would you take a screenshot of the title; does the loading feel like
  the game and not like waiting; is any parchment left anywhere; does a card look like a layer from another game.
- **Not a copy:** no other game's title picture, lettering or camera move. The picture shows our gorge, our castle
  and the house's lantern (DESIGN.md "Not a copy").
