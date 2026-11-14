# Lanternhold: the realm, its wealth and the dark side (14.11.2026, 14:35)

The director wrote this from Louis' words of the afternoon of 14.11.2026 and his answers in the interview that followed.
The numbers are starting values: the lanes tune them by values only.

## Louis' words (14.11.2026)

- "Das ist eine Mauer aus Bergen, da ist ein Durchgang, wir haben da drin eine Burg mit Mauer und verteidigen, und
  hinter uns ist ein Kontinent mit den anderen Ländern und Herrschern. Also ca. so wie bei Game of Thrones mit der
  Eismauer." (The shape only. Never that work's names, figures, places or look: DESIGN.md "Not a copy".)
- "Und wir machen halt unsere Burg, Königreich, Stadt, Land immer wohlhabender! Jetzt nicht so tief, aber so soll es
  halt wirken."
- A field is income. Nothing deeper.

## Decisions (Louis, by interview, 14.11. 14:32)

1. **The dark can be pushed back:** "Ja, Leuchtfeuer": beacons further and further into the gorge; each one drives the
   fog back and frees land.
2. **A lost night hurts and the game goes on:** houses burn, people with names die, the town is poorer and is built up
   again. It is over only when the hearth goes out, and then the player wakes at a dawn before.
3. **At night, being there counts:** where the lord stands his people fight better and hold longer; he raises the
   lantern. No battle menu: he runs to where it burns.

## 1. The premise in one picture

An unclimbable wall of mountains runs across the world. It has one cleft. Lanternhold sits in that cleft with its own
wall: the dark side in front (the gorge, the Gloom), the safe side behind (our town, our fields, the road), and beyond
them the inner lands with their rulers, who have never seen the dark because we stand here.

- Every wide shot, the title and the prologue show this at a glance: rock to both sides, our light in the gap.
- The inner lands stay light: guests, caravans, the nobles' manner, a line in the report. No politics to manage.

## 2. The wealth arc: poor at first, visibly richer

The player makes castle, town and land wealthier, and sees it everywhere. No new system: the standing of TOWN.md
section 3 is the number, this is its picture.

- **Three stages in chapter 1: hamlet, village, town** (standing 0 to 2, 3 to 6, 7 to 10). A fourth, the walled city,
  is kept for the endless mode and chapter 2.
- **What changes with a stage** (picture only): thatch to shingle to tile; mud to gravel to cobbles; more lit windows
  and more smoke; stalls on the market; carts, then caravans on the road from the inner lands; the hall from bare
  boards and tallow to hangings and many candles; the lord's own cloak from mended to good.
- **The people's cloth follows:** patched and faded at first, mended and whole in the village, good wool with a little
  colour in the town. Faces, backs and hands stay as life made them (BARS.md section 3): wealth changes the cloth,
  never the people.
- **The nobles turn:** in the hamlet they look past us and leave quickly; in the town they come to court us, bring
  gifts and ask for favours. Guests and lines only.
- **The moment:** when a stage is reached the bell rings at dawn, people stand in the doors, and the report says one
  line ("Lanternhold is a village now.").
- **The land:** more fields and farmsteads behind the town (TOWN.md) and freed land in front of the wall (section 5).

## 3. Being there counts (the night)

- **One front** (Louis, 14.11. 14:45; DESIGN.md says it too: one front, on the left). The Gloom comes only out of the
  gorge, so the night is never a run between two walls. At dusk the lord goes to the wall and stands with his people.
  His moves are in depth along that one line: forward to the outer line or the furthest beacon, at the gate, or back
  into the yard when something got through (crows over the wall, a breach). One or two such moves a night.
- **Presence.** At night defenders within about 90 px of the lord loose and strike 15 % faster and take 20 % less harm.
- **Braziers.** A dead brazier he passes within about 20 px is relit from his lantern, free (at most one in 4 s). The
  old "Light" action goes.
- **Patching** stays a deed at the wall: he stands at the damaged part and a touch on it pays the builders.
- **He cannot die.** A creature that reaches him throws him back about 60 px; for 8 s he is shaken and gives no
  presence.
- **Raise the lantern** (the stage lane's notes, item 3) stays as it is: the two do not share state.
- **The picture** (after the join): people near him straighten and shout, a warm rim on them. No HUD.
- **Bots and targets.** The reference bots get no presence, so T1 to T8 hold line for line. A new "present" bot goes
  to the wall at dusk and stays with the defenders. **T13:** over nights 3 to 14 it loses 25 to 40 % fewer defenders than the reference,
  and presence never wins a night the reference loses clearly.

## 4. The hearth (losing)

- **The hearth is the realm's life and is seen as fire:** bright, low, embers, out. No bar anywhere.
- **A broken night:** when creatures reach the hearth it drops one step and the night ends. By first light one or two
  houses are burnt (a field or the stall if no house stands), one to three townspeople with names are dead, a fifth of
  the purse is gone (at most 60) and happiness falls by 8.
- **Building up again:** a burnt house holds nobody and pays nothing until it is rebuilt for a third of its price; its
  household shelters in the chapel meanwhile.
- **The fire recovers:** a night without a breach raises it one step at dawn. Once a day the lord can feed it (wood for
  about 25 gold, one step).
- **Out:** the realm falls. The player wakes at one of the last three dawns (kept as saves), so nobody is stuck in a
  lost position; or begins a new realm.
- **Night 20:** the Lightless King at the hearth ends the chapter with the dark ending, as today.
- **Bots and targets.** For T1 to T8 a night in which the hearth is reached still counts as the loss it is today, so
  the numbers do not move. **T14:** one broken night can be mended within three days; two in three nights end it.

## 5. Beacons into the gorge (forward)

- **Four sites** beyond the gate at growing distances (kept as fractions of the gorge's length, so the rebuilt world
  places them). The next one is raised by day from day 3 (about 60, 90, 130, 180 gold; the builders need a day; each
  needs the one before it lit).
- **The fog line** moves out to the furthest lit beacon. Creatures appear at the fog line, so they walk longer under
  the arrows; the beacon lights its own pool.
- **Freed land,** one thing seen and one small gain per stretch (none above about 8 % on any system): the old quarry
  (wall and gate work cheaper), the ruined watchtower (a forward archers' post), the charcoal burners' camp (braziers
  burn longer), the far stones (the Great Beacon reaches further on night 20; picture only if the finale would move).
- **It must be held.** Creatures strike the furthest beacon as they pass. If it falls, the fog comes back to the one
  before; relighting by day costs a third. Forward is a wager: more time under the arrows against an outpost.
- **Bots and targets.** The reference bots never raise one, so T1 to T8 hold. A new "forward" bot. **T15:** with all
  four held by night 14 clearly fewer creatures reach the wall (the lane sets the band), and a player who builds
  beacons and neglects the wall loses them.

## 6. What is thin today, measured against the hits of the genre

The director's own reading on 14.11. (the hits as a bar for craft, never a model to copy):

| thin today | what the hits do | our answer |
|---|---|---|
| the night plays itself | the night tests the day and the player is in it | sections 3 and 4, raise the lantern, the flame shows the danger |
| the day has no pressure | the day is too short for everything | taxes on foot, the knock, feeding the hearth, the beacon to relight |
| nothing in front, nothing to find | the map opens piece by piece | section 5; fields and farmsteads behind |
| growth ends early | every session leaves something visibly bigger | section 2 |
| a lost night is all or nothing | a loss costs something you love and you go on | section 4 |
| judgments echo too quietly | a choice comes back with a face | the ledger; the people remember (build 3) |
| no way in | the first minute teaches by doing | the title is the world, the first sootling, Odile's counsel |
| long walks | short ways or a mount | the lord hurries; the collector from the first day |

Open questions the director watches: whether presence makes the night a chore (too many moves along the one line) and whether
taxes on foot cost too much of a 156 s day. Both are judged on the device with build 2.

## 7. Builds and lanes

- **Build 2 (Monday 16.11.):** taxes on foot; presence if its step passes its gate in time.
- **Build 3:** the hearth, the beacons, the wealth stages in the picture, with the town's growth and the craftsmen,
  and the drill yard (`docs/YARD.md`, 14.11. 16:04).
- **Core first** in a lane of its own (front, branch `claude/lh-front`, `docs/workflows/front-lane.js`); the screen
  side is hooked at the join, in the rebuilt gorge and hall.
- **People lane:** a second, better cloth state for every working figure (section 2).
- **World lane:** the fog line is a value the picture reads; room for four beacon sites beyond the gate.
