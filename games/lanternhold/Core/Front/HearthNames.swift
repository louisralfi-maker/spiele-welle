/// The townspeople a broken night can take, by name (docs/REALM.md section 4: "people with names die"). Plain first names
/// of the valley, none of them a soldier's (`Names.soldiers`), a member of the court or the house's past (STORY.md:
/// Odile, Brannock, Pip, Hesper, Tamsin, Bram, Marek, Seren, Aldric, Ludo, Taper, Oriel, Edric, Corwin, Ysmay) or one of
/// the people lane's cast (docs/PEOPLE.md: Wenna, Dun, Hedda, Gorm, Brede, Ned, Nib, Wren, Fen, Saul, Silas, Kell). No
/// name says an age (STORY.md rule 9: no dead children) or a gender the line would have to follow.
enum HearthNames {
    static let townsfolk: [String] = [
        "Ansel", "Berrit", "Cobb", "Dorrel", "Elske", "Faber", "Gisela", "Hob", "Imke", "Jannick", "Katrin", "Lammert",
        "Marit", "Nantwin", "Ottilie", "Pell", "Reinhild", "Siebold", "Trude", "Ulla", "Volker", "Wiebke", "Arnulf",
        "Beke", "Coen", "Dietlind", "Ebbe", "Femke", "Gerold", "Hiske", "Jost", "Kunna", "Lutz", "Meike", "Notker",
        "Okke", "Rike", "Tamme", "Tilla", "Wulf",
    ]

    /// A name from the stream that nobody in `used` carries (the living soldiers, the realm's dead, tonight's dead).
    /// When every name is taken, the name of the one who died longest ago comes round again (`dead`, by the night of
    /// their death; never one in `living`, never one who died on `night`, tonight): the valley names its children after
    /// its dead. Only if even that fails, a name with a number. One draw from the stream either way.
    static func pick(_ rng: inout SeededRandom, avoiding used: Set<String>, dead: [HearthDead] = [],
                     living: Set<String> = [], night: Int = Int.max) -> String {
        let start = rng.int(in: 0...(townsfolk.count - 1))
        for offset in 0..<townsfolk.count {
            let name = townsfolk[(start + offset) % townsfolk.count]
            if !used.contains(name) { return name }
        }
        var lastDeath: [String: Int] = [:]
        for entry in dead { lastDeath[entry.name] = max(lastDeath[entry.name] ?? Int.min, entry.night) }
        var best: (name: String, died: Int)?
        for offset in 0..<townsfolk.count {
            let name = townsfolk[(start + offset) % townsfolk.count]
            guard !living.contains(name), let died = lastDeath[name], died < night else { continue }
            if best.map({ died < $0.died }) ?? true { best = (name, died) }
        }
        if let best { return best.name }
        var number = 2
        while true {
            let name = townsfolk[start] + " " + String(number)
            if !used.contains(name) { return name }
            number += 1
        }
    }
}
