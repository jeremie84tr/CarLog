//
//  ExtensionCarLog.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import Foundation
import CoreData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CarLog", category: "CoreData")

extension NSManagedObjectContext {
    /// Sauvegarde le contexte s'il a des changements ; journalise l'erreur au lieu de planter.
    @discardableResult
    func saveLoggingErrors() -> Bool {
        guard hasChanges else { return true }
        do {
            try save()
            return true
        } catch {
            let nsError = error as NSError
            logger.error("Échec de la sauvegarde : \(nsError), \(nsError.userInfo)")
            return false
        }
    }
}

extension Part {
    convenience init(duplicating: Part, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = duplicating.name
        self.price = duplicating.price
    }
    
    var name: String {
        get {
            self.name_ ?? ""
        }
        set {
            self.name_ = newValue
        }
    }
}

extension Repair {
    convenience init(duplicating: Repair, context: NSManagedObjectContext) {
        self.init(context: context)
        if let parts = duplicating.parts?.allObjects as? [Part] {
            for part in parts {
                self.addToParts(.init(duplicating: part, context: context))
            }
        }
        self.price = duplicating.price
    }
}

extension Fuel {
    convenience init(duplicating: Fuel, context: NSManagedObjectContext) {
        self.init(context: context)
        self.full = duplicating.full
        self.price = duplicating.price
        self.quantity = duplicating.quantity
    }
}

extension Action {
    convenience init(duplicating: Action, context: NSManagedObjectContext) {
        self.init(context: context)
        self.mileage = duplicating.mileage
        self.location = duplicating.location
        self.reason = duplicating.reason
        self.timestamp = duplicating.timestamp
        if let fuel = duplicating.fuel {
            self.fuel = .init(duplicating: fuel, context: context)
        }
        if let repair = duplicating.repair {
            self.repair = .init(duplicating: repair, context: context)
        }
        
    }
    
    var timestamp: Date {
        get {
            self.timestamp_ ?? .now
        }
        set {
            self.timestamp_ = newValue
        }
    }
    var location: String {
        get {
            self.location_ ?? ""
        }
        set {
            self.location_ = newValue
        }
    }
    var reason: String {
        get {
            self.reason_ ?? ""
        }
        set {
            self.reason_ = newValue
        }
    }
    var price: Double {
        get {
            if let fuel = self.fuel {
                return fuel.price
            } else if let repair = self.repair {
                return repair.totalPrice
            }
            return 0
        }
    }
        
}

// MARK: - Calculs de dépenses et de consommation

struct CumulativeExpense: Identifiable {
    let id: Int
    let date: Date
    let accumulatedValue: Double
}

extension Collection where Element == Action {
    /// Dépenses cumulées par ordre chronologique.
    var cumulativeExpenses: [CumulativeExpense] {
        var total = 0.0
        return sorted(by: { $0.timestamp < $1.timestamp }).enumerated().map { index, action in
            total += action.price
            return CumulativeExpense(id: index, date: action.timestamp, accumulatedValue: total)
        }
    }

    /// Consommation L/100km de chaque plein complet, calculée en un seul passage
    /// (méthode « plein à plein »). Clé : objectID de l'Action.
    var fuelConsumptions: [NSManagedObjectID: Double] {
        var result = [NSManagedObjectID: Double]()
        var litersSinceLastFull = 0.0
        var lastFullMileage: Int64?
        let fuelActions = filter { $0.fuel != nil }.sorted(by: { $0.timestamp < $1.timestamp })
        for action in fuelActions {
            guard let fuel = action.fuel else { continue }
            if fuel.full {
                if let lastFullMileage {
                    let mileageDiff = Double(action.mileage - lastFullMileage)
                    if mileageDiff > 0 {
                        result[action.objectID] = (litersSinceLastFull + fuel.quantity) * 100.0 / mileageDiff
                    }
                }
                lastFullMileage = action.mileage
                litersSinceLastFull = 0
            } else {
                litersSinceLastFull += fuel.quantity
            }
        }
        return result
    }

    var totalExpenses: Double {
        self.reduce(0.0) { partialResult, element in
            if let fuel = element.fuel {
                return partialResult + fuel.price
            } else if let repair = element.repair {
                return partialResult + repair.totalPrice
            }
            return partialResult
        }
    }
}

extension Fuel {
    var quantityString: String {
        get {
            "\(quantity.shortNumber) L"
        }
    }
    /// nil tant que la quantité n'est pas saisie (évite inf/NaN).
    var eurosPerLiter: Double? {
        quantity > 0 ? price / quantity : nil
    }
}

extension Repair {
    var totalPrice: Double {
        get {
            if let parts = parts?.allObjects as? [Part] {
                return price + parts.reduce(0.0, {$0 + $1.price})
            }
            return price
        }
    }
}
