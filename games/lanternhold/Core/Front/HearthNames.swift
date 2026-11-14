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

    /// A name from the stream that nobody in `used` carries (the living soldiers, the realm's dead); when all are taken,
    /// a name with a number.
    static func pick(_ rng: inout SeededRandom, avoiding used: Set<String>) -> String {
        let start = rng.int(in: 0...(townsfolk.count - 1))
        for offset in 0..<townsfolk.count {
            let name = townsfolk[(start + offset) % townsfolk.count]
            if !used.contains(name) { return name }
        }
        var number = 2
        while true {
            let name = townsfolk[start] + " " + String(number)
            if !used.contains(name) { return name }
            number += 1
        }
    }
}
