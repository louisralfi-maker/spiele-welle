import Foundation

/// A version 1 save written by hand from the M2a schema and frozen: never regenerate it from the current code. Every
/// round decodes it (`SaveGameTests.testTheFrozenVersionOneSaveStillLoads`), so a non-optional field added to any
/// saved type fails CI instead of turning players' saves corrupt. It holds one of every saved type, also those a dawn
/// save leaves empty (a creature, a projectile, a glow, a spawn).
enum SaveFixtures {
    static let versionOne = #"""
{
 "adPacing": {
  "lastDoubleTaxesDay": 2,
  "lastInterstitialDay": 3,
  "lastSecondChanceNight": 0
 },
 "hintFlags": [
  "walk"
 ],
 "mode": "chapter",
 "settings": {
  "haptics": false,
  "sound": true
 },
 "state": {
  "bankEdge": 200,
  "beaconLit": false,
  "builders": [
   {
    "plot": -1,
    "task": "idle",
    "x": 1640
   },
   {
    "plot": 6,
    "task": "walking",
    "x": 930
   }
  ],
  "chapelBlessed": false,
  "citizens": 15,
  "creatures": [
   {
    "action": "perching",
    "gap": 4,
    "hp": 5,
    "id": 11,
    "incoming": 0,
    "isLit": true,
    "kind": "sootCrow",
    "lastHit": "none",
    "maxHP": 5,
    "speedScale": 1.02,
    "target": 8,
    "timer": 0.5,
    "wave": 2,
    "x": 880,
    "y": 44
   }
  ],
  "dawns": 3,
  "day": 4,
  "defeated": false,
  "flags": [],
  "glows": [
   {
    "duration": 2.5,
    "kind": "fireArrow",
    "radius": 22,
    "remaining": 1.5,
    "x": 870,
    "y": 2
   }
  ],
  "gold": 37,
  "guardPostX": 1440,
  "guardsHolding": false,
  "happiness": 66,
  "hearth": 100,
  "hour": 6,
  "king": {
   "facing": 1,
   "lightTimer": 0,
   "lightingPlot": -1,
   "patchCooldown": 0,
   "velocity": 0,
   "x": 1824
  },
  "lastHearthEvent": -10,
  "lastReport": {
   "citizensAfter": 15,
   "citizensBefore": 15,
   "creaturesDissolved": 3,
   "creaturesStopped": 40,
   "day": 4,
   "fallen": [
    {
     "kind": "archer",
     "name": "Gwyn"
    }
   ],
   "gloomReceded": false,
   "goldAfter": 37,
   "grown": 0,
   "happinessAfter": 66,
   "happinessBefore": 69,
   "happinessChanges": [
    {
     "delta": -3,
     "reason": "fallen"
    }
   ],
   "hearthLowest": 90,
   "left": 0,
   "night": 3,
   "taxes": {
    "fields": 5,
    "market": 0,
    "taxPart": 53,
    "taxpayers": 9,
    "unrest": false
   },
   "unlocked": [],
   "volunteer": false,
   "wallsLost": [
    "l2.wall"
   ]
  },
  "mode": "chapter",
  "nextID": 12,
  "night": {
   "arrows": 120,
   "braziersSnuffed": 0,
   "dissolved": 3,
   "fallen": [
    {
     "kind": "archer",
     "name": "Gwyn"
    }
   ],
   "fireArrows": 30,
   "gloomReceded": false,
   "hearthFirstHitSecond": 88.25,
   "hearthLowest": 90,
   "killed": 40,
   "killedByArchers": 30,
   "killedByEngines": 0,
   "killedByFire": 6,
   "killedByGuards": 1,
   "killedByTraps": 3,
   "lastSpawnSecond": 79.5,
   "maxCreatures": 19,
   "maxEntities": 42,
   "maxLights": 11,
   "night": 3,
   "patches": 1,
   "spawned": 43,
   "wallFallSeconds": [
    61.5
   ],
   "wallsLost": [
    "l2.wall"
   ]
  },
  "nightTime": 0,
  "orderCounter": 9,
  "plots": [
   {
    "cooldown": 0,
    "hp": 3650.5,
    "isRubble": false,
    "item": "gate",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "archerTower",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "brazier",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "brazier",
    "snuffed": true,
    "trapUses": 0
   },
   {
    "cooldown": 1.5,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "stakePit",
    "snuffed": false,
    "trapUses": 2
   },
   {
    "cooldown": 0,
    "hp": 300,
    "isRubble": false,
    "item": "palisade",
    "job": {
     "isRebuild": false,
     "order": 9,
     "target": "stoneWall",
     "total": 40,
     "work": 12.5
    },
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "house",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "field",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "house",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "house",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "item": "house",
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   },
   {
    "cooldown": 0,
    "hp": 0,
    "isRubble": false,
    "snuffed": false,
    "trapUses": 0
   }
  ],
  "projectiles": [
   {
    "damage": 4,
    "duration": 1.3,
    "elapsed": 0.25,
    "fromX": 1304,
    "fromY": 90,
    "kind": "arrow",
    "target": 11,
    "toX": 880,
    "toY": 50
   }
  ],
  "records": {
   "bestNight": 3,
   "creaturesStopped": 101,
   "fallenTotal": 1,
   "nightsWithoutLosses": 2
  },
  "rng": "9876543210123456789",
  "seed": 4242,
  "simTime": 864,
  "soldiers": [
   {
    "cooldown": 0,
    "goal": "reserve",
    "hp": 20,
    "id": 1,
    "kind": "archer",
    "maxHP": 20,
    "name": "Aldric",
    "postPlot": -1,
    "postSlot": 0,
    "shots": 0,
    "state": "reserve",
    "targetX": 1990,
    "x": 1990,
    "y": 0
   },
   {
    "cooldown": 0,
    "goal": "reserve",
    "hp": 20,
    "id": 2,
    "kind": "archer",
    "maxHP": 20,
    "name": "Brenna",
    "postPlot": -1,
    "postSlot": 0,
    "shots": 0,
    "state": "reserve",
    "targetX": 1990,
    "x": 1990,
    "y": 0
   },
   {
    "cooldown": 0,
    "goal": "posted",
    "hp": 17.5,
    "id": 3,
    "kind": "archer",
    "maxHP": 20,
    "name": "Corwin",
    "postPlot": 0,
    "postSlot": 0,
    "shots": 0,
    "state": "posted",
    "targetX": 1304,
    "x": 1304,
    "y": 90
   },
   {
    "cooldown": 0,
    "goal": "reserve",
    "hp": 30,
    "id": 4,
    "kind": "guardsman",
    "maxHP": 30,
    "name": "Dagny",
    "postPlot": -1,
    "postSlot": 0,
    "shots": 0,
    "state": "reserve",
    "targetX": 1440,
    "x": 1440,
    "y": 0
   },
   {
    "cooldown": 0,
    "goal": "reserve",
    "hp": 30,
    "id": 5,
    "kind": "guardsman",
    "maxHP": 30,
    "name": "Edwin",
    "postPlot": -1,
    "postSlot": 0,
    "shots": 0,
    "state": "reserve",
    "targetX": 1440,
    "x": 1440,
    "y": 0
   },
   {
    "cooldown": 0,
    "goal": "reserve",
    "hp": 20,
    "id": 9,
    "kind": "archer",
    "maxHP": 20,
    "name": "Ffion",
    "postPlot": -1,
    "postSlot": 0,
    "shots": 0,
    "state": "reserve",
    "targetX": 1990,
    "x": 1990,
    "y": 0
   }
  ],
  "spawns": [
   {
    "kind": "sootling",
    "time": 84,
    "wave": 3
   }
  ],
  "tax": "normal",
  "unheardPetitioners": 0,
  "warTaxUnlocked": false
 },
 "version": 1
}
"""#
}
