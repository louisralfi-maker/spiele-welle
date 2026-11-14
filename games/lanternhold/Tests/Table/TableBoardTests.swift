import Foundation
import XCTest
@testable import Lanternhold

/// The table screen's model (docs/QUESTS.md 5.2 and 6; the quests lane, step quests-3): the table top's map file agrees
/// with the catalogue and the art, the art ships at its sizes with binary alpha, the rail shows who is home, away or
/// lost, the line of light never tells the roll, every party gets its carved piece, and the screenshot set-ups work.
final class TableBoardTests: XCTestCase {
    private let balance = Balance.standard
    private let catalog = ErrandCatalog.standard
    private let map = TableMap.shared

    // MARK: - The map file

    func testTheMapHasEveryCarvedPlaceAndItsRoad() {
        XCTAssertEqual(map.width, 300)
        XCTAssertEqual(map.height, 150)
        for place in catalog.places where place.kind != .home {
            XCTAssertNotNil(map.place(place.id), "\(place.id) stands on the table")
        }
        XCTAssertEqual(map.place("moor_road")?.pinKind, "none", "the bare wood has no pin")
        let pins = map.pinned
        XCTAssertEqual(pins.count, 10, "ten places carry a pin")
        for (index, place) in pins.enumerated() {
            let p = place.pin
            XCTAssertTrue(p.x - 11 >= 0 && p.x + 11 < map.width && p.y - 11 >= 0 && p.y + 11 < map.height,
                          "\(place.id)'s hit box (22 px) lies on the table")
            let home = hypot(Double(p.x - map.home.x), Double(p.y - map.home.y))
            XCTAssertGreaterThanOrEqual(home, 24, "\(place.id) stands clear of the castle")
            for other in pins[(index + 1)...] {
                let distance = hypot(Double(p.x - other.pin.x), Double(p.y - other.pin.y))
                XCTAssertGreaterThanOrEqual(distance, 24, "\(place.id) and \(other.id) stand 24 px apart")
            }
            XCTAssertTrue(["brass", "iron", "varn", "brine", "lorn", "calder", "oxmoor"].contains(place.pinKind))
        }
        let houses = ["highcairn": "varn", "saltgate": "brine", "greybell": "lorn", "stillmere": "calder",
                      "goldenacre": "oxmoor"]
        for (id, house) in houses { XCTAssertEqual(map.place(id)?.pinKind, house, "\(id)'s pin in its house colour") }
        for place in map.places {
            XCTAssertEqual(place.road.first, map.home, "\(place.id)'s road starts at the castle")
            XCTAssertEqual(place.road.last, place.pin, "\(place.id)'s road ends at its pin")
            for (a, b) in zip(place.road, place.road.dropFirst()) {
                XCTAssertTrue(abs(a.x - b.x) <= 1 && abs(a.y - b.y) <= 1 && a != b, "\(place.id)'s road is unbroken")
            }
        }
        XCTAssertNotNil(map.bridge, "the old bridge's spot for the span")
    }

    // MARK: - The art

    @MainActor
    func testTheArtShipsAtItsSizesWithHardEdges() {
        let sizes: [String: (Int, Int)] = [
            "tableTop": (300, 150), "tableWest1": (96, 150), "tableWest2": (96, 150), "tableSpan": (16, 8),
            "tableCloth": (300, 150), "tablePins": (126, 9), "tableLantern": (14, 11), "tableRider": (12, 10),
            "tableWalker": (8, 10), "tableCart": (14, 9), "tableBearers": (16, 10), "tableRail": (128, 32),
            "tableHook": (5, 8), "tableRailLanterns": (18, 14), "tableSoot": (13, 16), "tableChalk": (7, 4),
            "tableDigits": (30, 5), "tableSeal": (9, 9),
        ]
        for (name, size) in sizes.sorted(by: { $0.key < $1.key }) {
            guard let image = TableArt.pixels(name) else {
                XCTFail("\(name).png is in the bundle")
                continue
            }
            XCTAssertEqual(image.width, size.0, "\(name) width")
            XCTAssertEqual(image.height, size.1, "\(name) height")
            var soft = 0
            for y in 0..<image.height {
                for x in 0..<image.width where image[x, y].a != 0 && image[x, y].a != 255 { soft += 1 }
            }
            XCTAssertEqual(soft, 0, "\(name) has binary alpha")
        }
        let top = TableArt.pixels("tableTop")
        XCTAssertEqual(top.map { opaque($0) }, 300 * 150, "the table top is solid")
    }

    private func opaque(_ image: PixelImage) -> Int {
        var count = 0
        for y in 0..<image.height { for x in 0..<image.width where image[x, y].a == 255 { count += 1 } }
        return count
    }

    @MainActor
    func testThePictureLightsTheRoadAndThePins() {
        var picture = TablePicture()
        for place in map.pinned { picture.pins[place.id] = .dull }
        picture.pins["tallowford"] = .lit
        picture.lines["highcairn"] = 0.5
        let image = picture.compose(map)
        XCTAssertEqual(image.width, 300)
        let road = map.place("highcairn")!.road
        let lit = TableBoard.litRoad(road, fraction: 0.5)
        XCTAssertEqual(lit.count, (road.count + 1) / 2)
        XCTAssertEqual(image[lit.last!.x, lit.last!.y], TableInk.fireWhite, "the light's head")
        XCTAssertEqual(image[lit[lit.count / 2].x, lit[lit.count / 2].y], TableInk.fireGold, "the lit road")
        let beyond = road[lit.count + 2]
        XCTAssertNotEqual(image[beyond.x, beyond.y], TableInk.fireGold, "the road ahead stays dark")
        var covered = TablePicture()
        covered.covered = true
        XCTAssertEqual(covered.compose(map), TableArt.pixels("tableCloth"), "day 1: the cloth")
    }

    // MARK: - The rail and the line of light

    func testTheRailTellsWhoIsHomeAwayOrLost() {
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 38), flags: []), .dark, "at home: dark on its hook")
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 41, reserved: true), flags: []), .dark)
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 39, state: .out), flags: []), .bare, "away: a bare hook")
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 39, state: .back), flags: []), .bare,
                       "home with its report: on the table, not yet on its hook")
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 40, state: .lost), flags: []), .charred, "lost: charred")
        XCTAssertEqual(TableBoard.hook(RoadLantern(number: 40, state: .lost), flags: ["hook_hidden"]), .blank,
                       "Bram's blank lantern")
    }

    private func sending(_ errand: String = "e", place: String = "highcairn", sent: Int, due: Int, late: Bool = false,
                         lost: Bool = false, goes: [String] = [], lent: Int = 0, citizens: Int = 0,
                         builders: Int = 0) -> Sending {
        let soldiers = (0..<lent).map { Soldier(id: 900 + $0, name: "S\($0)", kind: .archer, hp: 1, maxHP: 1, x: 0) }
        return Sending(errand: errand, order: 0, lantern: 38, place: place, sentDay: sent, sentAt: 0, dueDay: due,
                       homeDay: late ? due + 1 : due, lost: lost, late: late, sealed: false, lent: soldiers,
                       citizens: citizens, builders: builders, goes: goes, report: "r")
    }

    func testTheLineOfLightNeverTellsTheRoll() {
        let plain = sending(sent: 5, due: 8)
        XCTAssertEqual(TableBoard.lightFraction(plain, day: 5), 1.0 / 3.0, accuracy: 1e-9, "the day it left")
        XCTAssertEqual(TableBoard.lightFraction(plain, day: 6), 2.0 / 3.0, accuracy: 1e-9)
        XCTAssertEqual(TableBoard.lightFraction(plain, day: 7), 1, "full on the last day: home at the next dawn")
        XCTAssertEqual(TableBoard.lightFraction(sending(sent: 2, due: 3), day: 2), 1, "one night: full at once")
        for day in 5...9 {
            let fraction = TableBoard.lightFraction(plain, day: day)
            XCTAssertEqual(TableBoard.lightFraction(sending(sent: 5, due: 8, late: true), day: day), fraction,
                           "a late party's line reads the same on day \(day)")
            XCTAssertEqual(TableBoard.lightFraction(sending(sent: 5, due: 8, lost: true), day: day), fraction,
                           "a lost party's line reads the same on day \(day)")
        }
        let beyond = sending(place: "moor_road", sent: 19, due: ErrandEngine.neverHome)
        XCTAssertEqual(TableBoard.lightFraction(beyond, day: 19), 1, "Hild's lantern: the whole road")
        let road = map.place("highcairn")!.road
        XCTAssertEqual(TableBoard.litRoad(road, fraction: 0).count, 1, "at least the castle's gate")
        XCTAssertEqual(TableBoard.litRoad(road, fraction: 1), road)
    }

    func testEveryPartyHasItsCarvedPiece() {
        XCTAssertEqual(TableBoard.token(sending(place: "tallowford", sent: 2, due: 3, goes: ["pip"]), catalog: catalog),
                       .walker, "Pip walks")
        XCTAssertEqual(TableBoard.token(sending(place: "highcairn", sent: 5, due: 7, lent: 2), catalog: catalog),
                       .rider, "soldiers ride to a house")
        XCTAssertEqual(TableBoard.token(sending(place: "windmill", sent: 6, due: 7, lent: 1), catalog: catalog),
                       .rider, "and to the mill")
        XCTAssertEqual(TableBoard.token(sending(place: "goldenacre", sent: 8, due: 12, goes: ["marek"]),
                                        catalog: catalog), .cart, "Marek's cart")
        XCTAssertEqual(TableBoard.token(sending(place: "old_bridge", sent: 9, due: 12, citizens: 1, builders: 1),
                                        catalog: catalog), .cart, "the planks")
        XCTAssertEqual(TableBoard.token(sending(place: "greybell", sent: 15, due: 18, lent: 1, citizens: 2),
                                        catalog: catalog), .bearers, "the bell's bearers")
        XCTAssertEqual(TableBoard.token(sending(place: "beaconfoot", sent: 8, due: 9, lent: 1), catalog: catalog),
                       .walker, "a scout goes west on foot")
        XCTAssertEqual(TableBoard.token(sending(place: "saltgate", sent: 10, due: 13, goes: ["envoy"], lent: 1),
                                        catalog: catalog), .rider, "the envoy rides")
        XCTAssertEqual(TableBoard.token(sending(place: "moor_road", sent: 19, due: ErrandEngine.neverHome,
                                                goes: ["hildVarn"]), catalog: catalog), .rider, "Hild rides")
        for errand in catalog.errands {
            for index in errand.orders.indices {
                let order = errand.orders[index]
                let lend = order.lend ?? ErrandLend()
                let piece = TableBoard.token(sending(errand.id, place: errand.place, sent: 2, due: 3,
                                                     goes: order.goes ?? [],
                                                     lent: (lend.archers ?? 0) + (lend.guards ?? 0),
                                                     citizens: lend.citizens ?? 0, builders: lend.builders ?? 0),
                                             catalog: catalog)
                XCTAssertTrue(TableBoard.Token.allCases.contains(piece), "\(errand.id) order \(index)")
            }
        }
    }

    func testALanternStandsWhereItWent() {
        let out = sending(place: "stillmere", sent: 13, due: 16)
        XCTAssertEqual(TableBoard.lanternSpot(RoadLantern(number: 38, state: .out), sending: out, waiting: nil,
                                              map: map), map.place("stillmere")?.pin)
        let waiting = WaitingReport(report: "r", errand: "e", lantern: 39, place: "highcairn", day: 7)
        let home = TableBoard.lanternSpot(RoadLantern(number: 39, state: .back), sending: nil, waiting: waiting,
                                          map: map)
        XCTAssertNotNil(home, "home with its report: by the castle")
        if let home {
            XCTAssertLessThan(abs(home.x - map.home.x), 40)
            XCTAssertLessThan(abs(home.y - map.home.y), 10)
        }
        XCTAssertNil(TableBoard.lanternSpot(RoadLantern(number: 38), sending: nil, waiting: nil, map: map))
        XCTAssertNil(TableBoard.lanternSpot(RoadLantern(number: 40, state: .lost), sending: nil, waiting: nil,
                                            map: map), "a lost lantern stands nowhere")
    }

    // MARK: - The screenshot set-ups

    func testTheStagesSetUpTheRailAndAReport() {
        var s = GameState.newRealm(seed: 3, balance: balance)
        s.day = 11
        s.hour = 9
        s.gold = 200
        s.flags = ["varn_with"]
        ErrandEngine.uncover(&s, catalog: catalog)
        TableStage.stage("rail", &s, catalog: catalog, balance: balance)
        let table = s.table!
        XCTAssertEqual(table.lantern(38)?.state, .out, "38 rides to Highcairn")
        XCTAssertEqual(table.out.first?.place, "highcairn")
        XCTAssertEqual(table.lantern(39)?.state, .hook)
        XCTAssertEqual(table.lantern(40)?.state, .lost)
        XCTAssertEqual(table.lantern(41)?.state, .hook)

        var r = GameState.newRealm(seed: 3, balance: balance)
        r.day = 9
        ErrandEngine.uncover(&r, catalog: catalog)
        TableStage.stage("report:goldenacre_paid", &r, catalog: catalog, balance: balance)
        XCTAssertEqual(r.table?.reports.first?.report, "goldenacre_paid")
        XCTAssertEqual(r.table?.reports.first?.place, "goldenacre")
        XCTAssertEqual(r.table?.lantern(39)?.state, .back)
        XCTAssertEqual(ErrandEngine.nextReport(r.table!, catalog: catalog), 0, "it holds the table")

        var l = GameState.newRealm(seed: 3, balance: balance)
        l.day = 14
        ErrandEngine.uncover(&l, catalog: catalog)
        TableStage.stage("report:ludo_lost", &l, catalog: catalog, balance: balance)
        XCTAssertEqual(l.table?.reports.first?.lost, true)
        XCTAssertEqual(l.table?.lantern(39)?.state, .lost)
    }
}
