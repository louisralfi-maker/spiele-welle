/// Soldier names: plain fantasy first names (DESIGN.md "Defenders": every fallen soldier is named in the dawn report).
/// None of them belongs to the court (Odile, Brannock, Pip, Hesper, Tamsin, Bram, Marek, Seren, Aldric, Ludo).
enum Names {
    static let soldiers: [String] = [
        "Alda", "Aric", "Bertil", "Brenna", "Cael", "Corin", "Dagna", "Davor", "Edda", "Elric", "Fenna", "Finn",
        "Garrit", "Gilda", "Halvar", "Hedda", "Ivo", "Isolde", "Jorund", "Jessa", "Kester", "Kaia", "Lenn", "Liv",
        "Mabry", "Mira", "Nils", "Nessa", "Osric", "Orla", "Per", "Petra", "Quill", "Ragna", "Rowan", "Sander",
        "Sigrid", "Tobin", "Tova", "Ulric", "Una", "Varo", "Vesna", "Wendel", "Wren", "Yorick", "Ylva", "Zoran",
        "Agna", "Bjorn", "Calla", "Dirk", "Elva", "Folke", "Greta", "Hamon", "Ilse", "Jory", "Kelda", "Lorne",
        "Maren", "Nolan", "Oda", "Piet", "Runa", "Stig", "Thora", "Ugo", "Vilma", "Walter", "Edwin", "Hilde",
    ]

    /// The women among them (the dawn report names a fallen archer in her own form: German "Bogenschützin", M2b
    /// review).
    static let female: Set<String> = [
        "Alda", "Brenna", "Dagna", "Edda", "Fenna", "Gilda", "Hedda", "Isolde", "Jessa", "Kaia", "Liv", "Mabry",
        "Mira", "Nessa", "Orla", "Petra", "Ragna", "Sigrid", "Tova", "Una", "Vesna", "Wren", "Ylva", "Agna", "Calla",
        "Elva", "Greta", "Ilse", "Kelda", "Maren", "Oda", "Runa", "Thora", "Vilma", "Hilde",
    ]

    /// True for a woman's name (a numbered name like "Edda 2" counts as its first name).
    static func isFemale(_ name: String) -> Bool {
        female.contains(String(name.split(separator: " ").first ?? Substring(name)))
    }

    /// A name from the seeded stream that no living soldier carries; when all are taken, a name with a number.
    static func pick(_ rng: inout SeededRandom, avoiding used: [String]) -> String {
        let start = rng.int(in: 0...(soldiers.count - 1))
        for offset in 0..<soldiers.count {
            let name = soldiers[(start + offset) % soldiers.count]
            if !used.contains(name) { return name }
        }
        var number = 2
        while true {
            let name = soldiers[start] + " " + String(number)
            if !used.contains(name) { return name }
            number += 1
        }
    }
}
