# Lanternhold: the count, or how the lord pays (14.11.2026, 16:13)

The director wrote this from Louis' words of 14.11.2026. It holds for everything that is bought in the walked world:
buildings and their tiers (TOWN.md section 3), the drill yard, its works and recruiting (YARD.md), the craftsmen's
works, the beacons (REALM.md). The numbers are starting values: the lanes tune them by values only.

## Louis' words (14.11.2026)

"Wie bekommen wir aber das Upgrade-Kaufen so satisfying wie in Kingdom Two Crowns hin, ohne es nachzumachen? Also wenn
man da ja gedrückt hält oder tippt, wirft man immer eine Münze rein, checkst du?"

## What makes it feel good, and what is ours

What feels good there is not the look. It is four things, and all four are free to use:

1. every coin is seen and heard on its own;
2. the player sets the pace with his finger and can still stop;
3. the price is a row of empty places that fill, so no number is read;
4. the work starts in the same moment the last coin lands.

What is theirs, and never ours (DESIGN.md "Not a copy"): a rider who drops coins on the ground, coins that lie there and
are picked up, coins as the only input, the pouch on the screen.

What is ours:

- **A lord pays a person, hand to hand.** No coin ever touches the ground. The one who will do the work takes the money
  and answers for it: the court is the family (HOUSE.md).
- **The tally board.** A plain wooden board with hollows for coins, as a medieval paymaster used it. It is the price,
  the progress and the receipt in one thing.
- **Every purchase ends with a light.** The one who was paid lights the site lantern. "Light is life" is the game's
  third pillar: the realm gets brighter with every coin spent, and at night the player sees what he paid for.
- **The hand feels it.** One tick in the phone for every coin and one heavy beat for the seal.
- **Coins come as they go.** Taxes fly to the lord coin by coin (TOWN.md section 1); payments leave him coin by coin.
  Every coin in the game is seen and heard twice: once coming, once going.

## 1. The count, step by step

1. **Touch a thing that can be bought.** The lord walks there if he is not near. The tally board comes up at the
   thing, with one hollow for every coin of the price. The first coin already rocks above the first hollow: that is the
   whole tutorial.
2. **Hold.** The lord counts the coins onto the board, one hollow after the other. Every coin: a clink, a little
   higher than the last, and a light tick in the hand. The count starts slowly and gets faster. The gold on the HUD
   runs down coin by coin with it.
3. **Or tap.** Every tap sets one coin. Tapping and holding mix freely.
4. **Let go early, and nothing is paid.** After two seconds without a touch the coins slide back into the purse with a
   soft rustle and the board goes down. Nothing leaves the treasury before the board is full: a lord pays in full or
   not at all. So there is no "are you sure" and no mistaken purchase.
5. **The last coin** comes one short beat late. Then the seal: a deep sound, one heavy beat in the hand, the board snaps
   shut, the site lantern flares up warm, and the work starts in the same moment (the builders run in, the hammering
   begins, Bram turns to his forge, the recruit steps up).
6. **Not enough gold.** The count stops when the purse is empty. The empty hollows blink once, the `decline` sound
   plays, and the coins slide back. The player sees how many coins are missing, without a word.

## 2. The numbers

| thing | starting value |
|---|---|
| coins | a big coin counts ten, a small coin one (45 is four big and five small); no board has more than 20 hollows; if a price needs it, a bar counts a hundred |
| the board comes up | 0.15 s after the touch |
| the first coin, while holding | 0.3 s after the touch |
| the gap between coins | from 0.14 s down to 0.05 s |
| the whole count | never longer than 1.6 s |
| the beat before the last coin | 0.12 s |
| the clink | `coin`, each a small step higher, at most one octave in all |
| the seal | `seal`, then `lantern`, then the work's own sound (`build_start`) |
| the tick | a light impact per coin, growing from weak to strong; a heavy one at the seal |
| the coins slide back | 2 s after the last touch, in 0.3 s |

- No music: the rising clink is one sound effect at a rising pitch, never a tune.
- Reduce Motion: the coins appear in their hollows without a flight; the lantern lights without a flare.
- Haptics follow the game's own switch (`Feedback.swift`).
- VoiceOver: the thing says its price; a double tap pays in one step.

## 3. Who holds the board (build 3)

| what is bought | who holds the board and lights the lantern |
|---|---|
| a building or a tier, a wall, a beacon | the builders' foreman |
| the drill yard's stages, a recruit | Brannock, at the muster board (YARD.md section 6: the two badges are two small boards) |
| the pitch kettle, the pavises, the smithy's tiers | Bram |
| a craftsman's work | the craftsman himself, in the throne room or at his stall |

- The one who holds it follows the coins with his eyes and nods at the seal. One word at most ("Lord."). When the gold
  does not reach, he lowers the board and waits; he never begs and never mocks (HOUSE.md: everyone respects the lord).
- People stay as life made them (BARS.md section 3): the foreman's hands are a worker's hands.
- Until build 3 the board stands on a short post at the thing, held by nobody.

## 4. Core, bots and tests

- The count is picture and sound only. Core gets one order when the last coin lands, as today. Nothing is saved while
  a count runs.
- Bots buy in one step. No target moves.
- Unit tests: letting go before the board is full pays nothing; a full count pays once and only once; a price above
  the gold never pays; a count that is cut off (a card opens, the horn sounds, the app goes to the background) pays
  nothing.
- The UI test holds on one thing in English and German and saves the board half full, full, and the lit lantern.

## 5. Builds and lanes

- **Build 2 (Monday 16.11.2026):** the count in its plain form (sections 1 and 2, the board on its post), if the stage
  lane's pay step can take it without risk for Monday. If not, the second touch pays as planned and the count comes
  with build 3. The director decides on Sunday 15.11. from the lane's report.
- **Build 3:** all of it, with the people of section 3.
- **Lanes:** the stage lane builds the count once, as one reusable piece, and every purchase uses it. The town, craft
  and front lanes give it only a price and an order. The people lane draws the pose "holds the tally board" for the
  foreman, Brannock and Bram in its second round. The world lane draws the board, the two coins and the site lantern.
- **Gate.** The player critic judges on a screen recording or a row of screenshots: is it understood without a word;
  does it feel like paying a person and never like filling a slot machine; does anything look like the other game.
