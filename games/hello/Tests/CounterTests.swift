import XCTest
@testable import Hello

final class CounterTests: XCTestCase {
    func testEachTapAddsOne() {
        var counter = Counter()
        counter.tap()
        counter.tap()
        XCTAssertEqual(counter.value, 2)
    }

    func testSurvivesASaveRoundTrip() throws {
        var counter = Counter()
        counter.tap()
        let data = try JSONEncoder().encode(counter)
        XCTAssertEqual(try JSONDecoder().decode(Counter.self, from: data), counter)
    }
}
