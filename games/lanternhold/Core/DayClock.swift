/// The phases of a day (DESIGN.md "Day and night").
enum DayPhase: String, Sendable, CaseIterable, Equatable {
    /// 06:00 to 19:00: build, recruit, hold audience.
    case day
    /// 19:00 to 20:00: torches and windows light up, the darkness bank swells.
    case dusk
    /// 20:00 to 05:00: the waves attack.
    case night
    /// 05:00 to 06:00: the light sweeps in from the right and creatures dissolve.
    case firstLight
}

/// The moments a running clock crosses (DESIGN.md "Day and night").
enum ClockEvent: String, Sendable, CaseIterable, Equatable {
    /// 05:00: first light.
    case firstLight
    /// 06:00: the dawn report; a new day begins.
    case dawnReport
    /// 19:00: the horn; petitioners leave, builders return.
    case horn
    /// 20:00: night falls and the darkness bank advances.
    case nightfall

    /// The hour (0 ..< 24) of the event.
    var hour: Double {
        switch self {
        case .firstLight: return 5
        case .dawnReport: return 6
        case .horn: return 19
        case .nightfall: return 20
        }
    }

    /// Events in the order of the day, from midnight.
    static let ordered: [ClockEvent] = [.firstLight, .dawnReport, .horn, .nightfall]
}

/// Game time (DESIGN.md "Day and night"): 12 real seconds per in-game hour, 288 s per day. All time is simulation time,
/// never `Date()`. The day number grows at the dawn report (06:00), because a game day starts at dawn.
///
/// `elapsed` counts simulation seconds and keeps running while the clock is paused (audience, dawn report) or frozen
/// (`-GWFreezeTime`), so flicker and idle animations go on; only the hour stands still.
struct DayClock: Sendable, Equatable {
    /// Real seconds per in-game hour.
    static let secondsPerHour: Double = 12
    /// Hours per day.
    static let hoursPerDay: Double = 24

    /// The hour of the day, 0 ..< 24 (0 is midnight, 6.5 is 06:30).
    private(set) var hour: Double
    /// The day number, from 1; grows at every dawn report.
    private(set) var day: Int
    /// Simulation seconds since the clock was made, pauses and freezes included.
    private(set) var elapsed: Double = 0
    /// Gameplay pause: audience, dawn report, story scenes, the pause sheet.
    var isPaused = false
    /// Debug freeze (`-GWFreezeTime YES`).
    var isFrozen = false

    init(hour: Double = 6, day: Int = 1) {
        self.hour = DayClock.wrap(hour)
        self.day = max(1, day)
    }

    /// A clock at a `-GWTimeOfDay` position (0 midnight, 0.25 = 06:00, 0.5 noon, 0.8 = 19:12, 0.95 = 22:48).
    init(timeOfDay: Double, day: Int = 1) {
        self.init(hour: DayClock.hour(forTimeOfDay: timeOfDay), day: day)
    }

    /// Maps a time-of-day fraction 0 ... 1 to an hour 0 ..< 24; values outside 0 ... 1 are clamped, 1 is midnight.
    static func hour(forTimeOfDay timeOfDay: Double) -> Double {
        let clamped = min(1, max(0, timeOfDay))
        return wrap(clamped * hoursPerDay)
    }

    /// Any hour folded into 0 ..< 24.
    static func wrap(_ hour: Double) -> Double {
        var h = hour.truncatingRemainder(dividingBy: hoursPerDay)
        if h < 0 { h += hoursPerDay }
        if h >= hoursPerDay { h = 0 }
        return h
    }

    /// The phase of an hour (DESIGN.md "Day and night").
    static func phase(at hour: Double) -> DayPhase {
        let h = wrap(hour)
        if h >= 5 && h < 6 { return .firstLight }
        if h >= 6 && h < 19 { return .day }
        if h >= 19 && h < 20 { return .dusk }
        return .night
    }

    /// The clock position as a fraction of the day, 0 ..< 1.
    var timeOfDay: Double { hour / DayClock.hoursPerDay }

    /// The current phase.
    var phase: DayPhase { DayClock.phase(at: hour) }

    /// True from the horn (19:00) until the dawn report (06:00).
    var isDark: Bool { phase != .day }

    /// How far the current phase has run, 0 ..< 1.
    var phaseProgress: Double {
        let range = DayClock.range(of: phase)
        var into = hour - range.start
        if into < 0 { into += DayClock.hoursPerDay }
        return min(1, max(0, into / range.length))
    }

    /// Start hour and length in hours of a phase.
    static func range(of phase: DayPhase) -> (start: Double, length: Double) {
        switch phase {
        case .day: return (6, 13)
        case .dusk: return (19, 1)
        case .night: return (20, 9)
        case .firstLight: return (5, 1)
        }
    }

    /// The first event strictly after `hour`, with the hours until it (0 < gap ≤ 24).
    static func nextEvent(after hour: Double) -> (event: ClockEvent, gap: Double) {
        for event in ClockEvent.ordered where event.hour > hour {
            return (event, event.hour - hour)
        }
        let first = ClockEvent.ordered[0]
        return (first, first.hour + hoursPerDay - hour)
    }

    /// Runs the clock for `seconds` of simulation time and returns the events crossed, in order. An event exactly at
    /// the end of the step counts; the event at the starting hour does not count again. Paused or frozen, only
    /// `elapsed` moves.
    @discardableResult
    mutating func advance(by seconds: Double) -> [ClockEvent] {
        guard seconds > 0 else { return [] }
        elapsed += seconds
        if isPaused || isFrozen { return [] }
        var remaining = seconds / DayClock.secondsPerHour
        var events: [ClockEvent] = []
        while remaining > 0 {
            let next = DayClock.nextEvent(after: hour)
            if remaining < next.gap {
                hour = DayClock.wrap(hour + remaining)
                remaining = 0
            } else {
                hour = next.event.hour
                remaining -= next.gap
                events.append(next.event)
                if next.event == .dawnReport { day += 1 }
            }
        }
        return events
    }

    /// Sets the hour directly (debug arguments, story scenes); the day does not change.
    mutating func set(hour newHour: Double) {
        hour = DayClock.wrap(newHour)
    }
}
