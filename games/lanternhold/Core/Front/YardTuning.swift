/// Every number of the drill yard in one place (docs/YARD.md; build 3, wave 2, lane 2, step 1). It lives in
/// `Balance.yard`, so tests and the tuning run pass variants like every other balance number.
///
/// The rule applies only to a realm that carries `GameState.yard` (nil is the realm without a yard: stage 1, the
/// barracks only, nobody trained). The reference bots never build the yard, so T1 to T8 and T12 to T15 stay line for
/// line. Step 1 builds stage 2 (the drill yard), training and the pitch kettle; the pavises, the armoury and its
/// longbow and bill come in a later step, with their numbers.
struct YardTuning: Sendable, Equatable {
    // MARK: Stage 2, the drill yard (YARD.md section 2)

    /// The drill yard's price and the first day it can be ordered.
    var stagePrice = 70
    var stageDay = 4

    // MARK: Training (YARD.md section 3)

    /// The drill runs from this hour until that one; a day counts for every soldier on the roll.
    var drillFrom = 9.0
    var drillUntil = 16.0
    /// The roll is taken at noon: a man sworn in after it starts the next day.
    var rollHour = 12.0
    /// Days of drill until a recruit is trained (the armoury's two days come with the armoury).
    var trainDays = 3
    /// Trained: an archer looses every this many seconds (a recruit every `Balance.archerPeriod`, 1.4) ...
    var trainedArcherPeriod = 1.25
    /// ... and a guard holds this much (a recruit `Balance.guardHP`, 30).
    var trainedGuardHP = 36.0

    // MARK: Under the lord's eye (YARD.md section 3)

    /// The lord standing still within this many px of the fence's middle for this many seconds while they drill makes
    /// the day count this many times for everyone on the roll, once a day.
    var fenceReach = 24.0
    var fenceSeconds = 3.0
    var doubleDay = 2
    /// He counts as standing still below this speed (px per second).
    var stillSpeed = 1.0

    // MARK: The pitch kettle (YARD.md section 4)

    /// The kettle's price; ordered by day, Bram brings it at the next dawn and from that dusk every this many arrows
    /// is a fire arrow (without it `Balance.fireArrowEvery`, 4).
    var kettlePrice = 40
    var kettleFireEvery = 3
}
