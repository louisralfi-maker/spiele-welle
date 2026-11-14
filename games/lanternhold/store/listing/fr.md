# Lanternhold: fiche App Store, français (fr-FR)

Draft for the director (store lane, step store-1, 14.11.2026). The `text` blocks go into App Store Connect as they are.
Lines that start with `[if shipped]` describe parts not in the build yet: cut the line, or delete only the marker once
the part is in. `python3 games/lanternhold/store/tools/check_listing.py fr` counts the limits. Also fits fr-CA.

## Name

```text
Lanternhold
```

## Subtitle

```text
Bâtir le jour, tenir la nuit
```

## Promotional text

```text
Vingt nuits pour tenir l'unique passage d'un mur de montagnes. Bâtissez, rendez la justice et gardez les feux allumés : les Ténèbres ne craignent que la lumière.
```

## Description

```text
Tenez l'unique brèche d'un mur de montagnes face aux Ténèbres : de hautes silhouettes de fumée qui reculent devant la lumière.
Le jour, élevez murailles, tours et feux, tranchez les requêtes de votre peuple et gardez votre ville contente.
La nuit, la bataille se joue d'elle-même, et seul ce que vous avez bâti et allumé se dresse entre l'obscurité et votre âtre.

LE DERNIER ALLUMEUR DE LANTERNES
Depuis mille ans, la Maison Lantern garde la Faille, le seul passage à travers le Mur du Monde. Cet automne, le Grand Fanal s'est éteint. Le seigneur Aldric est parti le rallumer et n'est jamais revenu. Le diadème est échu au jeune allumeur de lanternes du château : vous. Nommez votre seigneur ou votre dame, prenez la perche à crochet et gardez la lumière.

LE JOUR : BÂTIR ET JUGER
• Élevez murailles, portes, tours et braseros au fond de la gorge, creusez des fosses à pieux, installez une baliste et une catapulte.
• Recrutez archers et gardes. Faites grandir la ville de la vallée : maisons, champs, un marché et une taverne.
• Entrez dans votre grande salle, asseyez-vous sur le trône et écoutez votre peuple : paysans, soldats, marchands, un barde, un chevalier qui croit dur comme fer à chacun de ses mots, les envoyés des autres grandes maisons. Chaque choix coûte ou rapporte de l'or et change l'humeur du peuple, et certains transforment le monde que vous parcourez.
• Fixez les impôts. Une ville contente paie et grandit. Une ville mécontente gronde.
• Parlez à votre cour : une chancelière pince-sans-rire, un capitaine bourru, un fou qui dit la vérité en plaisantant, une cuisinière qui connaît toutes les rumeurs, et une inconnue à la lanterne grise.
[if shipped] • Un registre près du trône garde la trace de vos jugements et de ce qu'il en est advenu.

LA NUIT : TENIR
• La lumière est la loi de la bataille. Dans le noir, les créatures sont invisibles et rapides. Dans la lumière, elles ralentissent, vos archers les voient et les plus petites brûlent.
• Les flèches enflammées zèbrent la nuit, les braseros jettent des flaques de lumière, les murailles se fissurent et tiennent bon.
• Sept sortes de créatures, des essaims de petites créatures de suie aux chiens d'ombre bondissants, jusqu'au Géant de cendre.
• Parcourez les remparts avec votre lanterne, colmatez un mur abîmé, rallumez un brasero éteint par les corbeaux.
[if shipped] • Levez haut votre lanterne : tout ce que touche sa lumière recule dans l'ombre.
• S'ils atteignent le feu de l'âtre dans votre grande salle, le domaine tombe.

VINGT NUITS
Le chapitre 1 dure vingt nuits, avec plus de 80 requêtes et une cour qui a ses propres secrets. Rebâtissez le Grand Fanal : le Roi sans Lumière ne peut être blessé que dans sa lumière.
[if shipped] Trois fins, racontées en images de lanterne magique, dépendent de la dernière nuit, de l'humeur de votre peuple et d'un choix difficile.
[if shipped] Le chapitre achevé, votre domaine tient encore, nuit après nuit, sans fin.
[if shipped] À la Table des lanternes, dans la chapelle, envoyez éclaireurs, messagers et émissaires au-dehors avec des lanternes numérotées. Toutes ne reviennent pas.

• Pixel art sous une lumière douce et vivante : feu chaud contre nuits bleues et froides, brume, pluie et braises
• Un jour et une nuit durent environ cinq minutes, et la partie est sauvegardée à chaque aube
• Effets sonores et vibrations uniquement, sans musique : votre propre musique peut jouer en même temps
• Pas de compte, pas d'achats intégrés
[if shipped] • En français, anglais, allemand, espagnol, italien, portugais, japonais et chinois
```

## Keywords

```text
château,médiéval,stratégie,siège,défense,pixel,fantasy,trône,seigneur,royaume,choix,archer
```

## What's New (1.0)

```text
Première version de Lanternhold : le chapitre 1, vingt nuits dans la Faille. Gardez la lumière.
```

## Notes

- Register: vous, as most French store pages (and Comet Cargo). Typography: a plain space before ":" (no-break spaces
  are invisible in App Store Connect and easy to lose).
- Terms chosen here, to align with the i18n lane's glossary at the join: la Maison Lantern (the name is never
  translated), la Faille (the Cleft), le Mur du Monde (the Worldwall), les Ténèbres (the Gloom), le Grand Fanal (the
  Great Beacon), le Roi sans Lumière, le Géant de cendre, l'allumeur de lanternes, le diadème (the circlet). "Le
  domaine" rather than "le royaume" in the text: the house holds a lordship, not a crown.
- Keywords repeat no word of the subtitle (bâtir, jour, tenir, nuit) and name no game or brand.
