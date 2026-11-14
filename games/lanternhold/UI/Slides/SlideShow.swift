import Foundation

/// The house's way of telling a story (panels lane, docs/lanes/panels.md): lantern slides, painted glass thrown on the
/// dark by a lantern. A show is plain data: which pictures, which texts, how long a slide holds. The prologue is the
/// first; the three endings and the story beats are the same kind of data later (STORY.md "The endings").

/// What a slide shows: one picture for everybody, or the Burgherr's and the Burgherrin's own (the prologue's fourth
/// slide shows the lord the player chose).
enum SlidePicture: Sendable, Equatable {
    case fixed(String)
    case byLord(lord: String, lady: String)

    /// The picture's resource name (a PNG in `Resources/Slides`) for this lord.
    func name(for form: LordForm) -> String {
        switch self {
        case .fixed(let name): return name
        case .byLord(let lord, let lady): return form == .lady ? lady : lord
        }
    }

    /// Every picture this slide may show.
    var names: [String] {
        switch self {
        case .fixed(let name): return [name]
        case .byLord(let lord, let lady): return [lord, lady]
        }
    }
}

/// How a slide keeps time. The player taps to go on (STORY.md "The prologue": one tap each); nothing turns by itself.
struct SlideTiming: Sendable, Equatable {
    /// Seconds after the slide came in before a tap turns it (a double tap must not skip the next slide unread).
    var hold: Double
    /// Seconds after the slide came in before its words fade in under it.
    var textDelay: Double
    /// Seconds the glass takes to slide in and settle.
    var settle: Double

    static let standard = SlideTiming(hold: 0.45, textDelay: 0.3, settle: 0.55)
    /// The first slide of a show comes up out of the dark a little slower.
    static let opening = SlideTiming(hold: 0.6, textDelay: 0.7, settle: 1.0)
}

/// One painted glass slide: its picture, its words (two short lines at most, the lines split by a line break in the
/// catalog) and an optional label on the glass (the prologue's last slide carries the lord's name).
struct Slide: Sendable, Equatable {
    var picture: SlidePicture
    /// The key of the words under the picture.
    var textKey: String
    /// The key of the small paper label stuck on the glass, if any.
    var labelKey: String?
    /// The string catalog of both keys ("Panels": this lane's own; the endings may read "Story").
    var table: String = SlideShow.table
    var timing: SlideTiming = .standard
}

/// A row of slides shown one after the other on the slide stage (`SlideStageView`).
struct SlideShow: Sendable, Equatable, Identifiable {
    /// This lane's string catalog (`Resources/Panels.xcstrings`).
    static let table = "Panels"
    /// The subfolder of the pictures in the bundle (`Resources/Slides`).
    static let folder = "Slides"
    /// The pictures' size in pixels (each pixel one painted cell of the glass): wide, 2 to 1.
    static let pictureWidth = 320
    static let pictureHeight = 160

    var id: String
    var slides: [Slide]
    /// A small "Skip" in the corner ends the show at once.
    var skippable = true

    /// Every picture the show may need, for the tests and the preload.
    var pictureNames: [String] { slides.flatMap(\.picture.names) }

    /// The prologue (STORY.md section 8): four slides before day 1, skippable, one tap each; the fourth shows the
    /// chosen lord or lady. The texts are STORY.md's, unchanged; Story.xcstrings had none of them yet, so they live in
    /// Panels.xcstrings with the label of the last slide.
    static let prologue = SlideShow(id: "prologue", slides: [
        Slide(picture: .fixed("slidePrologue1"), textKey: "slides.prologue.1", timing: .opening),
        Slide(picture: .fixed("slidePrologue2"), textKey: "slides.prologue.2"),
        Slide(picture: .fixed("slidePrologue3"), textKey: "slides.prologue.3"),
        Slide(picture: .byLord(lord: "slidePrologue4Lord", lady: "slidePrologue4Lady"), textKey: "slides.prologue.4",
              labelKey: "slides.prologue.4.label"),
    ])

    /// Every show by its id (`-GWSlides <id>` opens one directly).
    static let all: [SlideShow] = [prologue]

    static func named(_ id: String) -> SlideShow? {
        all.first { $0.id == id }
    }
}

/// The words of the slides in the player's language, with the lord's name and form filled in (`LordText`: `{lord}`
/// and `{a|b}`), as every story text.
enum SlideText {
    /// The text of `key` in `table` (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, table: String = SlideShow.table, lord: LordIdentity,
                       bundle: Bundle = .main) -> String {
        LordText.resolve(bundle.localizedString(forKey: key, value: key, table: table), lord: lord)
    }

    /// The text of `key` in one language ("en", "de") as the app bundle compiled it; nil when that language lacks it.
    static func string(_ key: String, table: String = SlideShow.table, language: String,
                       bundle: Bundle = .main) -> String? {
        guard let path = bundle.path(forResource: language, ofType: "lproj"), let localized = Bundle(path: path) else {
            return nil
        }
        let missing = "\u{1}missing\u{1}"
        let value = localized.localizedString(forKey: key, value: missing, table: table)
        return value == missing ? nil : value
    }

    /// Where a slide's picture lies in the bundle.
    static func pictureURL(_ name: String, bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: name, withExtension: "png", subdirectory: SlideShow.folder)
            ?? bundle.url(forResource: name, withExtension: "png")
    }
}

/// The launch arguments of the slides (DESIGN.md "Debug launch arguments" gets them at the join):
/// `-GWSlides <show>` opens that show directly over whatever the other arguments made (`prologue`; the lord is the one
/// `-GWLord` and `-GWLordName` name); `-GWPrologue YES|NO` says whether the prologue follows the name entry of a new
/// realm. Without it the prologue follows on a plain launch (the player's) and not under other `-GW` arguments, so every
/// UI test from before the slides starts as it did.
struct SlideArgs: Sendable, Equatable {
    static let keys = ["GWSlides", "GWPrologue"]

    /// The show to open at launch.
    var show: String?
    /// `-GWPrologue`: nil when not given.
    var prologue: Bool?

    init(values: [String: String]) {
        if let show = values["GWSlides"]?.trimmingCharacters(in: .whitespaces), !show.isEmpty {
            self.show = show
        }
        switch values["GWPrologue"]?.lowercased() {
        case "yes", "true", "1": prologue = true
        case "no", "false", "0": prologue = false
        default: prologue = nil
        }
    }

    static func fromProcess() -> SlideArgs {
        var values: [String: String] = [:]
        for key in keys {
            if let value = UserDefaults.standard.string(forKey: key) { values[key] = value }
        }
        return SlideArgs(values: values)
    }

    /// Whether the prologue follows the name entry: `-GWPrologue` decides; without it a plain launch plays it and a
    /// launch with other debug arguments (`hasArguments`, or `-GWSlides`) does not.
    func prologueFollowsEntry(hasArguments: Bool) -> Bool {
        prologue ?? !(hasArguments || show != nil)
    }
}
