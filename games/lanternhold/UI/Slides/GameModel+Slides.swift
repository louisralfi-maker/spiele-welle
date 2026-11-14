import Foundation

/// The slide stage's part of the screen state machine (panels lane, docs/lanes/panels.md): a show covers the world and
/// the realm stands still under it (the simulation does not step, as under a screen), then the world comes back as it
/// was. The prologue follows the name entry of a new realm (the one hook in `confirmLord`); `-GWSlides <show>` opens a
/// show directly at launch.
extension GameModel {
    /// Opens `show` over the world for the realm's lord; `then` runs when it has ended (the last tap or "Skip").
    /// Nothing steps while it shows; afterwards the realm steps again unless a card or screen is still open.
    func presentSlides(_ show: SlideShow, then: (() -> Void)? = nil) {
        guard kind == .world, !slides.isShowing else {
            then?()
            return
        }
        closeTalk()
        withDriver { game in
            game.isPaused = true
            game.setDrag(offset: nil)
        }
        let started = slides.present(show, lord: lord) { [weak self] in
            guard let self else { return }
            let covered = self.overlay != nil
            self.withDriver { $0.isPaused = covered }
            self.refreshHUD()
            then?()
        }
        if !started {
            let covered = overlay != nil
            withDriver { $0.isPaused = covered }
            then?()
        }
        refreshHUD()
    }

    /// The hook after the name entry's "Begin" (`confirmLord`): day 1 begins after the prologue, when this launch
    /// plays it (`SlideArgs.prologueFollowsEntry`).
    func presentPrologueAfterEntry() {
        guard SlideArgs.fromProcess().prologueFollowsEntry(hasArguments: args.hasArguments) else { return }
        presentSlides(.prologue)
    }

    /// `-GWSlides <show>`: that show at once over whatever the other arguments made (once per run).
    func openSlidesFromLaunch() {
        guard !slides.launchHandled else { return }
        slides.launchHandled = true
        guard let id = SlideArgs.fromProcess().show, let show = SlideShow.named(id) else { return }
        presentSlides(show)
    }

    /// A tap on the stage: the next glass slides in with a soft click, or the show ends after the last.
    func turnSlide() {
        switch slides.next() {
        case .turned, .finished: feedback.play(.cardClosed)
        case .ignored: break
        }
    }

    /// "Skip": the show ends at once and the day goes on.
    func skipSlides() {
        if slides.skip() { feedback.play(.cardClosed) }
    }
}
