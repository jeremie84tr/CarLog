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
    convenience init(duplicating: Part, context: NSManagedObjectContext = PersistenceController.unowned.container.viewContext) {
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
    convenience init(duplicating: Repair, context: NSManagedObjectContext = PersistenceController.unowned.container.viewContext) {
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
    convenience init(duplicating: Fuel, context: NSManagedObjectContext = PersistenceController.unowned.container.viewContext) {
        self.init(context: context)
        self.full = duplicating.full
        self.price = duplicating.price
        self.quantity = duplicating.quantity
    }
    func fuelConsumption(_ viewContext: NSManagedObjectContext) -> Double? {
        guard let entityName = Action.entity().name, let action = action, full == true else { return nil }
        
        let fetchRequest = NSFetchRequest<Action>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "timestamp_ < %@ AND fuel != nil", action.timestamp as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Action.timestamp_, ascending: false)]
        
        do {
            let previousActions = try viewContext.fetch(fetchRequest)
            
            if let lastFullIndex = previousActions.firstIndex(where: { $0.fuel?.full == true }) {
                let range = previousActions.prefix(upTo: lastFullIndex)
                let fuelConsumed = range.reduce(quantity) { result, action in
                    result + (action.fuel?.quantity ?? 0.0)
                }
                
                let mileageDiff = Double(action.mileage - previousActions[lastFullIndex].mileage)
                guard mileageDiff > 0 else { return nil }
                
//                print("\(fuelConsumed) litres consommés sur \(mileageDiff) km entre \(previousActions[lastFullIndex].timestamp) et \(action.timestamp)")
                return (fuelConsumed * 100.0) / mileageDiff
            }
            
        } catch {
            print("Erreur lors du fetch pour consommation : \(error)")
        }
        
        return nil
    }
}

extension Action {
    convenience init(duplicating: Action, context: NSManagedObjectContext = PersistenceController.unowned.container.viewContext) {
        self.init(context: context)
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
