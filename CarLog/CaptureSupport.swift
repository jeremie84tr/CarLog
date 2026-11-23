//
//  CaptureSupport.swift
//  CarLog
//
//  Mode « captures App Store » (DEBUG uniquement) : jeu de données fictif en mémoire et écran
//  choisi par argument de lancement. Utilisé par AppStore/outils/captures.sh.
//    -donneesExemple 1            données fictives, store en mémoire (pas d'iCloud)
//    -ecran liste|statistiques|plein|reparation
//
#if DEBUG
import SwiftUI
import CoreData

enum CaptureSupport {
    static var actif: Bool { UserDefaults.standard.bool(forKey: "donneesExemple") }
    static var ecran: String { UserDefaults.standard.string(forKey: "ecran") ?? "liste" }

    /// Store en mémoire rempli de données fictives, identiques à chaque lancement.
    @MainActor static let controller: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let ctx = result.container.viewContext
        let cal = Calendar(identifier: .gregorian)
        func date(_ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: m, day: d, hour: 12))! }

        // (mois, jour, km, lieu, motif, litres, prix total, plein complet)
        let pleins: [(Int, Int, Int64, String, String, Double, Double, Bool)] = [
            (1, 9, 142_300, "Leclerc", "Plein", 41.2, 74.16, true),
            (1, 28, 142_910, "Intermarché", "Plein", 39.8, 72.44, true),
            (2, 16, 143_540, "Total", "Plein", 25.0, 47.50, false),
            (2, 24, 143_850, "Leclerc", "Plein", 18.6, 33.48, true),
            (3, 14, 144_510, "Carrefour", "Plein", 42.3, 76.14, true),
            (4, 5, 145_160, "Leclerc", "Plein", 40.7, 75.30, true),
            (4, 27, 145_820, "Intermarché", "Plein", 41.9, 79.61, true),
            (5, 19, 146_470, "Total", "Plein", 39.5, 76.99, true),
            (6, 11, 147_150, "Leclerc", "Plein", 43.1, 82.75, true),
            (7, 2, 147_830, "Carrefour", "Plein", 42.0, 81.48, true),
            (8, 14, 148_900, "Intermarché", "Plein vacances", 44.6, 84.74, true),
            (9, 6, 149_540, "Leclerc", "Plein", 40.2, 77.19, true),
            (10, 1, 150_190, "Total", "Plein", 41.4, 79.49, true),
            (10, 25, 150_850, "Leclerc", "Plein", 42.7, 80.51, true),
            (11, 12, 151_300, "Carrefour", "Plein", 29.8, 56.51, true),
        ]
        for (m, d, km, lieu, motif, litres, prix, plein) in pleins {
            let a = Action(context: ctx)
            a.timestamp = date(m, d); a.mileage = km; a.location = lieu; a.reason = motif
            let f = Fuel(context: ctx)
            f.quantity = litres; f.price = prix; f.full = plein
            a.fuel = f
        }

        // (mois, jour, km, lieu, motif, forfait, [(pièce, prix)])
        let reparations: [(Int, Int, Int64, String, String, Double, [(String, Double)])] = [
            (3, 2, 144_300, "Garage Martin", "Vidange", 60, [("Huile 5W30", 38.50), ("Filtre à huile", 14.90)]),
            (6, 20, 147_400, "Contrôle technique", "Contrôle technique", 78, []),
            (9, 18, 149_900, "Garage Martin", "Freins avant", 90, [("Plaquettes", 62.00), ("Disques", 118.00)]),
            (11, 4, 151_100, "Norauto", "Pneus hiver", 48, [("Pneu 205/55 R16 x4", 356.00)]),
        ]
        for (m, d, km, lieu, motif, forfait, pieces) in reparations {
            let a = Action(context: ctx)
            a.timestamp = date(m, d); a.mileage = km; a.location = lieu; a.reason = motif
            let r = Repair(context: ctx)
            r.price = forfait
            for (nom, prix) in pieces {
                let p = Part(context: ctx)
                p.name = nom; p.price = prix
                r.addToParts(p)
            }
            a.repair = r
        }
        try? ctx.save()
        return result
    }()

    /// Racine de l'app selon `-ecran`.
    @MainActor @ViewBuilder static func racine() -> some View {
        let ctx = controller.container.viewContext
        let req = Action.fetchRequest()
        let _ = req.sortDescriptors = [NSSortDescriptor(keyPath: \Action.timestamp_, ascending: false)]
        let actions = (try? ctx.fetch(req)) ?? []
        switch ecran {
        case "statistiques":
            NavigationView { StatisticsView(actions: actions).inlineNavigationTitle() }
                .stackNavigationViewStyle()
        case "plein":
            NavigationView { ActionView(action: actions.first { $0.fuel?.full == true && $0.fuel?.quantity == 42.7 } ?? actions[0]) }
                .stackNavigationViewStyle()
        case "reparation":
            NavigationView { ActionView(action: actions.first { $0.repair?.parts?.count == 2 && $0.mileage == 149_900 } ?? actions[0]) }
                .stackNavigationViewStyle()
        default:
            ContentView()
        }
    }
}
#endif
