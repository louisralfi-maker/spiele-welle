import SwiftUI

/// A report laid on the table as a letter (QUESTS.md 2.5 and 5.2: the audience card's parts, docs/UI-look.md): the
/// speaker's portrait in its inked frame, the name in small capitals and the role as a rubric, whose lantern came home
/// from where, and the report itself. Its choices stand in the column, under the thumb.
struct TableReportLetter: View {
    let waiting: WaitingReport
    let report: TableReport
    let realm: GameState
    let lord: LordIdentity
    let speaker: (name: String, role: String?)
    let place: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                PortraitTile(portrait: AudienceCard.portrait(speaker: report.speaker,
                                                             look: waiting.lantern * 7 + waiting.day,
                                                             day: realm.day, flags: realm.flags), side: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text(speaker.name)
                        .font(Theme.caps(.headline))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let role = speaker.role {
                        Text(role)
                            .font(Theme.caps(.footnote))
                            .foregroundStyle(Theme.rubric)
                            .lineLimit(1)
                    }
                    Text(inked: QuestText.text(waiting.lost ? "table.lost" : "table.home",
                                               values: ["lantern": String(waiting.lantern)]) + " · " + place,
                         .footnote)
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            InkRule()
            TableHugging {
                ScrollView(.vertical, showsIndicators: false) {
                    Text(inked: QuestText.text(report.text, lord: lord, values: ["lantern": String(waiting.lantern)]),
                         .callout)
                        .font(Theme.serif(.callout))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("table-report-text")
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(14)
        .background(ParchmentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-report")
    }
}

/// The answer to a report, on the same letter: the lord's word, the reaction in italic, what it did.
struct TableReactionLetter: View {
    let note: TableReaction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(note.title.hasSuffix(".") ? String(note.title.dropLast()) : note.title)
                .font(Theme.caps(.headline))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            FlourishRule()
            if !note.text.isEmpty {
                Text(note.text)
                    .font(Theme.italic(.body))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TableChipRow(chips: note.chips)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ParchmentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-reaction")
    }
}
