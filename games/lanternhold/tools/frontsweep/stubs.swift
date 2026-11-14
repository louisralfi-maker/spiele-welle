// Stand-ins for the sweep only: the lord's identity lives in Core/Lord.swift, which pulls in the sprite tables. Nothing
// in the simulation reads it (GameState.lord is for the screens).
struct LordIdentity: Codable, Sendable, Equatable {
    static let standard = LordIdentity()
}
