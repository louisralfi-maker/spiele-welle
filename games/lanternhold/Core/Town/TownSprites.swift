/// The sprites of the taxes on foot (docs/TOWN.md section 1, "The sign", "The knock", "The picture"; town-2). Every one
/// is a hand-set grid built by `tools/taxart.py` through `tools/actorart.py` (the figures, the lord's knock, the coin)
/// or cut from the house's own painting (the open door, the closed shutters), so the grid, the palette and the outline
/// rule are the game's own. `SpriteID.size` and `SpriteID.frameCount` ask this file; the contract is in
/// `docs/lanes/town.md` ("town-2").
enum TownSprites {
    /// The households in the doorways, worn working people of the town (the people lane's bodies, docs/PEOPLE.md):
    /// Mother Corra at the chandler's (house 1), Dun Rook at the oil-presser's (house 3), Brede Hask at the cooper's
    /// (house 4), Old Hemmet at the weaver's (house 5), Wenna Brisk at the market stall.
    static let households: [SpriteID] = [.townCorra, .townDun, .townBrede, .townHemmet, .townWenna]
    /// Every figure of the town's taxes: the households, Gorm Ashby the farmer at the field, and Nib Brisk, the child
    /// who sometimes runs out with the coins.
    static let figures: [SpriteID] = households + [.townGorm, .townNib]
    /// Every sprite of this file.
    static let all: [SpriteID] = figures + [.kingKnock, .ladyKnock, .townCoin, .townCottage, .townBigHouse]

    /// A household's frames (12x26, the citizen contract: the foot at the bottom centre, facing right).
    enum Frame {
        /// Waiting, the hands held a little forward, a breath (0 and 1); the coin in them is `townCoin`, drawn by the
        /// engine at `heldCoin` (fix round 1), so it glints and glows.
        static let wait = 0
        /// The toss: the hand drawn back with the coins, the throw, the open hand after it.
        static let wind = 2
        static let toss = 3
        static let follow = 4
        /// The wave (5 and 6), from 60 happiness on.
        static let wave = 5
        /// Below 30 happiness: the coins flung down at the lord's feet.
        static let fling = 7
        /// The knock: the head bowed and the coins held out, then the deeper bow.
        static let bow = 8
        static let bowDeep = 9
        /// Empty-handed.
        static let stand = 10
        /// Mother Corra only (the first morning: she walks home to the town): the walk 11 ... 14.
        static let walk = 11
    }

    /// The farmer's frames (12x26): waiting at the field with the knotted cloth (0 and 1), counting the coins out of
    /// it (2 and 3).
    enum FarmerFrame {
        static let wait = 0
        static let count = 2
    }

    /// The child's frames (10x18, the children's contract): running out with the coins 0 ... 3, holding them up in the
    /// door 4, the throw 5, skipping home 6 ... 8.
    enum ChildFrame {
        static let run = 0
        static let hold = 4
        static let toss = 5
        static let skip = 6
    }

    /// The lord's knock (16x30, the lord's contract): the fist drawn back, the knock, the hand held out for the coins.
    /// His far hand knocks; the pole and lantern stay where the walking sprite's standing frame `lantern` holds them,
    /// so his glow strip keeps that frame while he knocks (fix round 1). Fix round 2: the open palm is held low, at
    /// belt height under and before the lantern (`TownShow.lordHand`), and gives a pixel down and back as a coin lands
    /// in it (`give`); the same palm takes a toss while he stands.
    enum KnockFrame {
        static let ready = 0
        static let knock = 1
        static let receive = 2
        static let give = 3
        /// The walking sprite's frame (the standing pose) whose pole, lantern glass and circlet the knock pose keeps.
        static let lantern = 6
    }

    /// The coin's frames (4x4): the spin in flight 0 ... 3 (face, three quarters, edge, three quarters), and the face
    /// with its highlight a pixel larger, the glint of a held coin.
    enum CoinFrame {
        static let face = 0
        static let spin = 4
        static let glint = 4
    }

    /// Where the coin of a waiting figure is drawn (fix round 1): its centre from the figure's anchor (game px; ahead
    /// of it, mirrored with it) and above the ground, resting on the palm its grid's waiting frames hold out at the
    /// waist (0 and 1; the breath lowers it a pixel on 1), on the farmer's knotted cloth, over the child's raised fist
    /// (her frame 4). nil for every other sprite and frame. Keep in step with `tools/taxart.py` (`HELD`) and the grids'
    /// waiting arms.
    static func heldCoin(_ sprite: SpriteID, frame: Int) -> (dx: Double, dy: Double)? {
        let anchor: (dx: Double, dy: Double)
        switch sprite {
        case .townCorra, .townDun, .townBrede, .townWenna: anchor = (5, 14)
        case .townHemmet: anchor = (6, 9)
        case .townGorm: anchor = (5, 16)
        case .townNib:
            return frame == ChildFrame.hold ? (4, 13) : nil
        default:
            return nil
        }
        guard frame == Frame.wait || frame == Frame.wait + 1 else { return nil }
        return (anchor.dx, anchor.dy - Double(frame - Frame.wait))
    }

    /// The house overlays (the house's size, drawn over it at its place and with its mirror): the cottages' open door
    /// (frame 0) and the closed shutters of `house`, `houseB` and `houseC` (1, 2, 3); the big house's open door (0)
    /// and closed shutters (1).
    enum OverlayFrame {
        static let door = 0
        static let shutters = 1
    }

    static func size(of sprite: SpriteID) -> PixelSize {
        switch sprite {
        case .townCorra, .townDun, .townBrede, .townHemmet, .townWenna, .townGorm:
            return PixelSize(width: 12, height: 26)
        case .townNib: return PixelSize(width: 10, height: 18)
        case .kingKnock, .ladyKnock: return PixelSize(width: 16, height: 30)
        case .townCoin: return PixelSize(width: 4, height: 4)
        case .townCottage: return PixelSize(width: 64, height: 46)
        case .townBigHouse: return PixelSize(width: 72, height: 56)
        default: return PixelSize(width: 1, height: 1)
        }
    }

    /// The frames of a sprite of this file; nil for every other sprite.
    static func frameCount(of sprite: SpriteID) -> Int? {
        switch sprite {
        case .townCorra: return 15
        case .townDun, .townBrede, .townHemmet, .townWenna: return 11
        case .townGorm: return 4
        case .townNib: return 9
        case .kingKnock, .ladyKnock: return 4
        case .townCoin: return 5
        case .townCottage: return 4
        case .townBigHouse: return 2
        default: return nil
        }
    }

    /// The figure who pays for a place: the household of each of the four house plots, the stall keeper, the farmer.
    static func figure(plot: Int, kind: TownPlaceKind) -> SpriteID {
        switch kind {
        case .field: return .townGorm
        case .market: return .townWenna
        case .house:
            if plot == Realm.plotID("town.house.3") { return .townDun }
            if plot == Realm.plotID("town.house.4") { return .townBrede }
            if plot == Realm.plotID("town.house.5") { return .townHemmet }
            return .townCorra
        }
    }

    /// The lord's knock sprite for the Burgherr or the Burgherrin.
    static func knock(_ lord: LordIdentity) -> SpriteID {
        lord.form == .lady ? .ladyKnock : .kingKnock
    }
}
