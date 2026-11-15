import SwiftUI

/// Touch the world, fix round 1 (stage lane, step stage-2; the critic's high 6): the audience's "Next petitioner" was
/// a big plaque of wax red at the screen's bottom right, where the action button stood, the reddest thing on the
/// screen: it still felt like a menu. It is an inked plaque now like the choices, its words and rule in House
/// Lantern's teal: the next one rising from his bench is the cue, the plaque only answers it. At least 52 pt high.
struct TealPlaqueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        // Night glass (stage-3-interface; the director's note of 15.11. 05:36): a quiet plaque in the choices' place.
        GlassQuietButtonStyle(inside: false).makeBody(configuration: configuration)
    }
}
