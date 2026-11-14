import Foundation

/// The chapter's end in the screen state machine (panels-2, docs/lanes/panels.md). After the finale's dawn report
/// (night 20) the ending the realm earned plays as three lantern slides on its own light; the end card follows on the
/// same dark stage with the realm's tale, "Begin again" (a new realm) and "Hold the realm" (the Long Watch: Core's
/// endless mode from night 21 on). The world stands still under both.
extension GameModel {
    /// The hook in `continueReport`: the finale's dawn report was read; a chapter realm ends here.
    func endChapterIfFinale(_ report: DawnReport) {
        guard kind == .world, report.night == ReportCard.finaleNight, let state = driver?.state,
              state.mode == .chapter, !slides.coversWorld else { return }
        presentEnding(RealmTale.make(state: state, report: report))
    }

    /// The hook at launch (`GameModel.init`): a realm saved at the finale's dawn that never chose how to go on (the
    /// app was closed on the ending or the end card) gets its ending again. Only on a plain launch, the player's:
    /// a UI test that starts a realm past night 20 starts as it did.
    func resumeChapterEndAtLaunch() {
        guard kind == .world, !args.hasArguments, overlay == nil, let state = driver?.state, state.mode == .chapter,
              let report = state.lastReport, report.night == ReportCard.finaleNight, state.day == report.day,
              !state.defeated else { return }
        presentEnding(RealmTale.make(state: state, report: report))
    }

    /// The ending's three slides; after the last tap (or "Skip") the end card.
    func presentEnding(_ tale: RealmTale) {
        presentSlides(tale.show()) { [weak self] in
            self?.openEndCard(tale)
        }
    }

    /// The end card lies on the stage; the realm stays still under it.
    func openEndCard(_ tale: RealmTale) {
        guard kind == .world else { return }
        closeTalk()
        slides.endCard = tale
        withDriver { game in
            game.isPaused = true
            game.setDrag(offset: nil)
        }
        refreshHUD()
    }

    /// Core has the endless mode (`GameMode.endless`: the Long Watch's nights beyond 20, its petitions, its records;
    /// tuned by T7), so the end card offers to hold the realm. Its events (eclipse, festival, crows) are not built.
    var canHoldTheRealm: Bool { true }

    /// "Begin again", after the card asked (`end-begin-confirm`): a new realm on day 1, as the pause sheet's "Restart
    /// chapter" makes it (the Chronicle stays; the name entry asks who holds it).
    func beginAgain() {
        guard slides.endCard != nil else { return }
        slides.endCard = nil
        feedback.play(.cardClosed)
        setOverlay(.pause)
        restartChapter()
    }

    /// "Hold the realm": the realm goes on into the Long Watch from the morning of day 21 (Core's endless mode; the
    /// save counts it on the endless track from now on).
    func holdTheRealm() {
        guard slides.endCard != nil, canHoldTheRealm else { return }
        slides.endCard = nil
        feedback.play(.cardClosed)
        withDriver { $0.holdTheRealm() }
        saveNow()
        setOverlay(nil)
    }
}
