/// The smallest piece of game logic: plain Swift, no UI, so the unit tests can check it.
struct Counter: Equatable, Codable {
    private(set) var value = 0

    mutating func tap() {
        value += 1
    }
}
