import SwiftUI
import UIKit

/// The chapter's end card (panels-2, docs/lanes/panels.md; docs/UI-look.md): after an ending's last slide the glass
/// slides away and a page of the house chronicle lies in the lantern's beam on the same dark stage, in the ending's own
/// light. It tells the realm's tale in the few things a player cares about: the nights held, the judgments spoken, the
/// fallen, the lord's way (the leaning's name) and who stood by (the banners of the houses, drawn as the hall hangs
/// them, or House Lantern alone). Then "Hold the realm" (the Long Watch) as the main button and "Begin again" (a new
/// realm) as a quiet plaque in wax red that asks first. Identifiers: `end-root`, `end-ending` (value: the ending's id),
/// `end-nights`, `end-judgments`, `end-fallen`, `end-way`, `end-stood`, `end-begin`, `end-hold`, `end-begin-ask`,
/// `end-begin-cancel`, `end-begin-confirm`.
@MainActor
struct ChapterEndView: View {
    let model: GameModel
    let tale: RealmTale
    @State private var shown = false
    /// "Begin again" was tapped once: the card asks before this realm ends.
    @State private var askingToBegin = false

    private var look: SlideLampLook { SlideLampLook.of(tale.ending.lamp) }
    private var reduceMotion: Bool { model.reduceMotion }

    private func text(_ key: String) -> String { SlideText.string(key, lord: tale.lord) }

    var body: some View {
        ZStack {
            SlideSurround(look: look)
                .ignoresSafeArea()
            GeometryReader { geometry in
                let width = min(640, geometry.size.width - 40)
                let height = min(330, geometry.size.height - 16)
                ZStack {
                    // The lantern's spill on the wall around the page, as around the glass a moment ago.
                    SlideBeam(size: CGSize(width: width, height: height), reduceMotion: reduceMotion, look: look)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    page
                        .frame(width: width)
                        .frame(maxHeight: geometry.size.height - 12)
                        .opacity(shown ? 1 : 0)
                        .offset(y: shown || reduceMotion ? 0 : 8)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("end-root")
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.3 : 0.7).delay(reduceMotion ? 0 : 0.25)) { shown = true }
        }
    }

    // MARK: The page

    private var page: some View {
        VStack(spacing: 0) {
            header
            CardScroll {
                HStack(alignment: .top, spacing: 22) {
                    ledger
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    stood
                        .frame(maxWidth: 230, alignment: .topLeading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 4)
            }
            buttons
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .background(ParchmentBackground())
    }

    private var header: some View {
        VStack(spacing: 2) {
            // The ledger's figures for the digits (docs/UI-look.md "Type"): IM Fell's old-style 1 reads as an i.
            Text(inked: text("end.lord") + " \u{00B7} " + text("end.chapter"), .subheadline)
                .font(Theme.italic(.subheadline))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(verbatim: text(tale.ending.nameKey))
                .font(Theme.caps(.title2))
                .foregroundStyle(Theme.rubric)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("end-ending")
                .accessibilityValue(Text(verbatim: tale.ending.rawValue))
            FlourishRule()
                .frame(maxWidth: 300)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    /// The realm's numbers, each led by dots to its figure, and the lord's way by its name.
    private var ledger: some View {
        VStack(alignment: .leading, spacing: 7) {
            EndRow(label: text("end.nights"), identifier: "end-nights") {
                Text(inked: "\(tale.nightsHeld)", .body)
            }
            EndRow(label: text("end.judgments"), identifier: "end-judgments") {
                Text(inked: "\(tale.judgments)", .body)
            }
            EndRow(label: text("end.fallen"), identifier: "end-fallen") {
                Text(inked: "\(tale.fallen)", .body)
            }
            EndRow(label: text("end.way"), identifier: "end-way") {
                Text(verbatim: text(tale.leaning.nameKey))
                    .font(Theme.italic(.body))
                    .foregroundStyle(Theme.teal)
            }
        }
    }

    /// Who stood by: the banners of the houses as the hall hangs them, their names under them; or House Lantern alone.
    private var stood: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: text("end.stood"))
                .font(Theme.caps(.footnote))
                .tracking(1)
                .foregroundStyle(Theme.rubric)
            if tale.houses.isEmpty {
                Text(verbatim: text("end.alone"))
                    .font(Theme.italic(.body))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(tale.houses, id: \.self) { house in
                        EndBanner(name: house.banner)
                    }
                }
                Text(verbatim: tale.housesList())
                    .font(Theme.italic(.subheadline))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("end-stood")
    }

    @ViewBuilder private var buttons: some View {
        if askingToBegin {
            beginQuestion
        } else {
            choices
        }
    }

    /// Critic 1 of panels-2, high 5: the main button goes on (the realm is kept), as the main button does everywhere in
    /// the game; the button that ends this realm is quiet with wax-red words and asks first, as the pause sheet's
    /// "Restart chapter" does.
    private var choices: some View {
        HStack(spacing: 14) {
            Spacer(minLength: 0)
            if model.canHoldTheRealm {
                Button {
                    model.holdTheRealm()
                } label: {
                    Text(verbatim: text("end.hold"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(GoldButtonStyle())
                .accessibilityHint(Text(verbatim: text("end.hold.hint")))
                .accessibilityIdentifier("end-hold")
            }
            Button {
                askingToBegin = true
            } label: {
                Text(verbatim: text("end.begin"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(QuietButtonStyle(danger: true))
            .accessibilityHint(Text(verbatim: text("end.begin.hint")))
            .accessibilityIdentifier("end-begin")
            Spacer(minLength: 0)
        }
    }

    /// The second tap: a new realm ends this one. Cancel is the main button.
    private var beginQuestion: some View {
        VStack(spacing: 6) {
            Text(verbatim: text("end.begin.ask"))
                .font(Theme.caps(.headline))
                .foregroundStyle(Theme.rubric)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("end-begin-ask")
            Text(verbatim: text("end.begin.ends"))
                .font(Theme.serif(.subheadline))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                Spacer(minLength: 0)
                Button {
                    askingToBegin = false
                } label: {
                    Text(verbatim: text("end.cancel"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(GoldButtonStyle())
                .accessibilityIdentifier("end-begin-cancel")
                Button {
                    askingToBegin = false
                    model.beginAgain()
                } label: {
                    Text(verbatim: text("end.begin"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(QuietButtonStyle(danger: true))
                .accessibilityHint(Text(verbatim: text("end.begin.hint")))
                .accessibilityIdentifier("end-begin-confirm")
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
}

/// One line of the chronicle's ledger: the entry in roman, dots, the figure.
private struct EndRow<Value: View>: View {
    let label: String
    let identifier: String
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: label)
                .font(Theme.serif(.body))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Leader()
            value()
                .foregroundStyle(Theme.ink)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

/// A house's banner as it hangs in the hall (`Resources/Art`, 20 x 41), at whole device pixels: one point per painted
/// pixel on every iPhone.
private struct EndBanner: View {
    let name: String
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let scale = max(1, displayScale.rounded()) / max(1, displayScale)
        Group {
            if let image = EndBannerImages.image(name) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
            } else {
                Theme.teal
            }
        }
        .frame(width: 20 * scale, height: 41 * scale)
        .accessibilityHidden(true)
    }
}

/// The houses' banners, read once from the game's art.
@MainActor
enum EndBannerImages {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let image = cache[name] { return image }
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Art")
            ?? bundle.url(forResource: name, withExtension: "png"),
            let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache[name] = image
        return image
    }
}
