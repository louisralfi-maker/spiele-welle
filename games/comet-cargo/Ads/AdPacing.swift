import Foundation

/// What the game is doing when the player leaves a flight report: the only moment an interstitial may come.
struct AdMoment: Equatable, Sendable {
    /// Flights the player has finished ever (the save's counter, this flight included).
    var flightsEver: Int
    /// A first-flight hint is still being taught.
    var hintsActive = false
    /// Something is presented over the game (a sheet, the consent form, another ad).
    var overlayShowing = false
    /// The player started the rewarded ad ("Double it") on this flight report: never two ads for one report.
    var rewardedThisReport = false

    init(flightsEver: Int, hintsActive: Bool = false, overlayShowing: Bool = false, rewardedThisReport: Bool = false) {
        self.flightsEver = flightsEver
        self.hintsActive = hintsActive
        self.overlayShowing = overlayShowing
        self.rewardedThisReport = rewardedThisReport
    }
}

/// The interstitial's pacing: rare and never early (Louis, 08.11.2026). Pure rules over an injected clock (seconds on
/// a monotonic clock, `ProcessInfo.systemUptime` in the app), so the unit tests need no wall clock.
///
/// - none before 3 minutes of play in this session (time in the foreground; the background does not count),
/// - none in the player's first three flights ever,
/// - then at most one every 210 s,
/// - none while a first-flight hint is still taught, none over a sheet,
/// - none on a report where the player watched the rewarded ad, and none within 60 s after a rewarded ad closed.
struct AdPacing: Equatable, Sendable {
    static let warmUp: TimeInterval = 180
    static let gap: TimeInterval = 210
    static let afterRewarded: TimeInterval = 60
    static let freeFlights = 3

    /// Play time of this session before `activeSince`.
    private(set) var playedBefore: TimeInterval = 0
    /// When the app last came to the foreground; nil while it is in the background.
    private(set) var activeSince: TimeInterval?
    private(set) var lastInterstitial: TimeInterval?
    private(set) var lastRewarded: TimeInterval?

    /// A session that starts (in the foreground) at `now`.
    init(startedAt now: TimeInterval) {
        activeSince = now
    }

    /// Seconds of play in this session at `now`.
    func playTime(at now: TimeInterval) -> TimeInterval {
        guard let activeSince else { return playedBefore }
        return playedBefore + max(0, now - activeSince)
    }

    mutating func becameActive(at now: TimeInterval) {
        guard activeSince == nil else { return }
        activeSince = now
    }

    mutating func resignedActive(at now: TimeInterval) {
        playedBefore = playTime(at: now)
        activeSince = nil
    }

    func allowsInterstitial(at now: TimeInterval, moment: AdMoment) -> Bool {
        if moment.hintsActive || moment.overlayShowing || moment.rewardedThisReport { return false }
        if moment.flightsEver <= Self.freeFlights { return false }
        if playTime(at: now) < Self.warmUp { return false }
        if let lastInterstitial, now - lastInterstitial < Self.gap { return false }
        if let lastRewarded, now - lastRewarded < Self.afterRewarded { return false }
        return true
    }

    mutating func interstitialShown(at now: TimeInterval) {
        lastInterstitial = now
    }

    /// A rewarded ad closed (watched or not): no interstitial right after it.
    mutating func rewardedClosed(at now: TimeInterval) {
        lastRewarded = now
    }
}
