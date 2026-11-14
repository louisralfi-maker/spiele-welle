import Foundation
import Observation
import UIKit

/// The slide stage's state (panels lane): which show is up, which slide, and what happens when it ends. The view is
/// `SlideStageView`; the model's glue (pausing the realm, the prologue after the name entry, `-GWSlides`) is
/// `GameModel+Slides.swift`. Plain enough to test without a screen: `clock` can be set.
@MainActor
@Observable
final class SlideStage {
    /// What a tap did.
    enum Step: Equatable {
        /// Too soon after the slide came in (its `hold`), or nothing is showing.
        case ignored
        /// The next slide came in.
        case turned
        /// That was the last slide: the show ended.
        case finished
    }

    /// The show on the stage; nil while the stage is dark and gone.
    private(set) var show: SlideShow?
    /// The slide showing, 0 based.
    private(set) var index = 0
    /// Counts every slide that came in (also across shows), so the view animates each change.
    private(set) var turn = 0
    /// The lord whose picture and name the slides show (set when the show starts).
    private(set) var lord = LordIdentity.standard

    /// When the current slide came in, on `clock`.
    @ObservationIgnored private(set) var cameAt = 0.0
    @ObservationIgnored private var onFinish: (() -> Void)?
    /// `-GWSlides` is looked at once per run.
    @ObservationIgnored var launchHandled = false
    /// Seconds on a steady clock (tests set their own).
    @ObservationIgnored var clock: () -> Double = { ProcessInfo.processInfo.systemUptime }

    init() {}

    var isShowing: Bool { show != nil }

    /// The slide showing.
    var slide: Slide? {
        guard let show, show.slides.indices.contains(index) else { return nil }
        return show.slides[index]
    }

    var isLast: Bool {
        guard let show else { return false }
        return index >= show.slides.count - 1
    }

    /// Starts `show` at its first slide for `lord`; `onFinish` runs once when it ends (by the last tap or by "Skip").
    /// A show already up is not interrupted: the call is refused (false) and `onFinish` is not kept.
    @discardableResult
    func present(_ show: SlideShow, lord: LordIdentity, onFinish: @escaping () -> Void) -> Bool {
        guard self.show == nil, !show.slides.isEmpty else { return false }
        self.lord = lord
        self.onFinish = onFinish
        index = 0
        turn += 1
        cameAt = clock()
        self.show = show
        return true
    }

    /// A tap on the stage: the next slide, or the end after the last.
    @discardableResult
    func next() -> Step {
        guard let show, let slide else { return .ignored }
        guard clock() - cameAt >= slide.timing.hold else { return .ignored }
        if index + 1 < show.slides.count {
            index += 1
            turn += 1
            cameAt = clock()
            return .turned
        }
        finish()
        return .finished
    }

    /// "Skip": the show ends at once (false when nothing is showing or the show cannot be skipped).
    @discardableResult
    func skip() -> Bool {
        guard let show, show.skippable else { return false }
        finish()
        return true
    }

    private func finish() {
        let done = onFinish
        onFinish = nil
        show = nil
        index = 0
        done?()
    }
}

/// The slides' pictures, read once from the bundle and kept (a show's six pictures are a few kilobytes each).
@MainActor
enum SlidePictures {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let image = cache[name] { return image }
        guard let url = SlideText.pictureURL(name), let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache[name] = image
        return image
    }
}
