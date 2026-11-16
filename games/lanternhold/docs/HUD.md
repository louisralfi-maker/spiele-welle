# Lanternhold: nothing on the world, and the lantern moment (14.11.2026, 18:26)

The director wrote this from Louis' words of 14.11.2026. It replaces the HUD paragraph of `docs/UI-look.md` and the
pause seal on the world. It spells out the interface bar (`ci-out/director/artbar.md` section 2), which stays in force.

## Louis' words (14.11.2026)

"Muss dir sagen, das UI sieht auch scheiße aus. Kannst du mir 5 UI-Vorschläge machen und ich such einen aus." After
five quick sketches (the lantern, the beam, the seal and others): "Such du aus, finde aber alle nicht den Knüller."

## The director's finding and decision

- Build 86 looks bad for two reasons. Smooth parchment, ink and a wax seal lie on a world of pixels, so the interface
  reads as a layer from another game. And three framed things always stand on the picture.
- A better frame does not mend that. **Nothing stands on the walked world.** The picture is the game.
- What must be known comes at the lord, in the world's own pixels, when it is asked for or when it changes.

## 1. The rule

1. A screenshot of the lord walking, by day or by night, shows no interface at all.
2. Whatever appears on the world is drawn on the world's pixel grid and from its palette: pixel figures in bone with
   a dark edge, no plate, no parchment, no smooth shape, no shadow, no system type.
3. The desk (pause sheet, defeat card) and the cards for words stand on night glass (`docs/TITLE.md` section 4).
   No parchment is left anywhere (Louis, 15.11.2026). The title is `docs/TITLE.md`.

## 2. The lantern moment (touch the lord)

- **Touch the lord:** he raises the house's lantern and **the world stands still**. Everything dims a little and
  nothing moves but the flame. It is the pause, the purse and the map in one touch.
- **Above him,** in one row: the coin with the gold, the face (mood), the people with their count. The face is a
  townsman's head in a hood: thrown back when glad, worn when even, pulled low when grim, red and shouting in unrest.
- **Under the row,** centred: the day, as the dawn sign (a half sun on the horizon) and its number. No word and no
  letter stands on the walked world, so nothing there is translated and no pixel font is needed; the dawn report
  teaches the sign. The hour is never a figure. The day line's bottom is 8 game px above the lord's head.
- **Top centre:** the realm strip (stage-3, H5). A touch on a point lowers the lantern and he walks there.
- **In a corner,** small: the gear. It opens the pause sheet.
- **Any other touch** lowers the lantern and the world runs on. There is no pause button anywhere.
- It answers at once (0.15 s up, 0.1 s down). If the lord has no such pose, the lantern's glow flares instead.
- The app going to the background raises the lantern by itself.
- VoiceOver: the lord is an element ("{name}, day 12, 93 gold, the town is content, 28 people; double tap to pause").

## 3. What comes by itself

- **Gold:** while coins reach the lord (TOWN.md section 1) or leave him (PAY.md), the coin and the figure stand above
  him and tick with every coin. They go 2 s after the last coin. The stage lane builds this once; it follows the
  purse, so no other lane hooks anything.
- **Mood and people:** on a change, the face or the people with a small arrow up or down, 2 s, above the lord.
- **A call** (a petitioner waits, a breach, the collector is back): the realm strip comes up with its tag and goes
  when the call is answered. Otherwise the strip is away.

## 4. The time is told by the world

- The sky and the light. At 18:00 the lamplighter walks and the soldiers climb to their posts (YARD.md section 5).
- **The lord's own lantern:** from one game hour before the horn its glow breathes faster and turns a shade redder;
  at night it burns steady. Picture only. Reduce Motion: the colour alone.
- The horn's ribbon stays as it is.

## 5. Gone

The ledger slip top right, the pause seal top left, the realm strip as a standing thing, the action seal (stage-2).

## 6. Builds, lanes and the gate

- **Build 2 (Monday 16.11.2026):** the stage lane, in stage-3-interface. **The kit is drawn** (14.11.2026, 20:10;
  `tools/hudart.py`, branch `claude/lh-hudart`, commits 479a4c9 and 0b687b5, judged by the director on real
  screenshots at noon, dusk and night): figures 0 to 9, plus and minus, the two arrows, the small coin and the big
  coin (ten) with their tally hollows for PAY.md, the hood face in four moods, the people, the dawn sign, the gear.
  Ten strips, 30 frames, a row of 9 game px (18 pt). The stage lane takes the two commits and wires them in; it draws
  nothing of the kit itself. The proofs and the note with sizes and spacing: `ci-out/director/hud-kit/` and
  `ci-out/director/hud-kit.md`.
- **If the round is at risk, cut in this order:** the lantern's breathing (section 4); the change notes; the strip's
  hiding (it then stands at 60 %). Sections 2 and 5 and the gold at the lord are never cut.
- **Build 3:** the cards on the world are looked at again under rule 2; a call becomes a small pennant at the
  screen's edge instead of the whole strip.
- **Gate.** The player critic, on screenshots at phone size and one row of the lantern moment: does a walking shot
  show nothing; is the gold read on noon sky, dusk and night; does a first-time player find the pause inside a
  minute; does anything on the world look like a layer from another game.
- **Not a copy:** no pouch, no coin on the ground, nothing of another game's screen (DESIGN.md "Not a copy").


## Decision of 16.11.2026: the town's mood stands at the map

Louis asked for a sign beside the map that shows how the townspeople feel. Without it, caring for them reads as
optional. This changes section 2 for build 3:

- The hood face and the people's count leave the row above the lord. They stand at the realm strip, at its town
  end. The lord's row keeps the purse alone.
- The face is bigger than today and carries the mood in colour as well as in its pose: warm gold when glad, bone
  when even, cold grey when grim, wax red in unrest. A short finer reading stands beside it (a design card decides
  its form before it is built).
- On a change the small arrow shows as today. A touch on the face gives one slip with the main reason in a few
  words, such as "The tax is high."
- Nothing of it stands on the walked world: it shows with the strip, in the lantern moment and on a call.
