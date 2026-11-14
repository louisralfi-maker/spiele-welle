import XCTest
@testable import Lanternhold

/// The speed kit's plan (App/SweepRunner.swift): what the UI test hands over reads as a launch with the same
/// arguments would.
final class SweepPlanTests: XCTestCase {
    private func encoded(_ list: [[String: Any]]) -> [String: String] {
        let data = try! JSONSerialization.data(withJSONObject: list)
        return [SweepPlan.environmentKey: data.base64EncodedString()]
    }

    func testAShotReadsAsItsLaunch() {
        let values = ["GWScene": "probe", "GWCameraX": "760", "GWTimeOfDay": "0.95", "GWFreezeTime": "YES",
                      "GWFlickerTime": "2.5", "GWLook": "1"]
        let plan = SweepPlan.from(environment: encoded([["name": "04-front-night", "values": values]]))
        XCTAssertEqual(plan?.shots.count, 1)
        XCTAssertEqual(plan?.args(at: 0), DebugArgs(values: values))
        XCTAssertEqual(plan?.marker(at: 0), "0 04-front-night")
        XCTAssertEqual(plan?.marker(at: 1), "done")
    }

    func testUnknownKeysAreLeftOutAsAtLaunch() {
        let plan = SweepPlan.from(environment: encoded([["name": "a", "values": ["GWNoSuchKey": "1"]]]))
        XCTAssertEqual(plan?.args(at: 0), DebugArgs(values: [:]))
        XCTAssertEqual(plan?.args(at: 0).hasArguments, false)
    }

    func testNoPlanWithoutTheEnvironment() {
        XCTAssertNil(SweepPlan.from(environment: [:]))
        XCTAssertNil(SweepPlan.from(environment: [SweepPlan.environmentKey: "not base64"]))
        XCTAssertNil(SweepPlan.from(environment: encoded([])))
    }

    func testTheNextNames() {
        XCTAssertEqual(SweepPlan.nextName(after: 7), "gw.sweep.next.7")
        XCTAssertEqual(SweepPlan.index(inNextName: "gw.sweep.next.12"), 12)
        XCTAssertNil(SweepPlan.index(inNextName: "gw.sweep.done.1"))
    }
}
