//
//  Persistence.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static let unowned: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        do {
            try? viewContext.save()
        }
        return result
    }()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newAction = Action(context: viewContext)
        newAction.timestamp = Date()
        newAction.reason = "Plein chez leclerc"
        newAction.location = "Leclerc morrières"
        newAction.mileage = 198002
        let fuel = Fuel(context: viewContext)
        fuel.full = false
        fuel.quantity = 32.1
        fuel.price = 52.01
        newAction.fuel = fuel
        let newAction2 = Action(context: viewContext)
        newAction2.timestamp = Date()
        newAction2.reason = "Entretien"
        newAction2.location = "Garage méca'nico"
        newAction2.mileage = 199293
        let repair = Repair(context: viewContext)
        repair.price = 48
        let part1 = Part(context: viewContext)
        part1.name = "Pompe à carburant"
        part1.price = 74
        repair.addToParts(part1)
        let part2 = Part(context: viewContext)
        part2.name = "Filtres"
        part2.price = 23.99
        repair.addToParts(part2)
        let part3 = Part(context: viewContext)
        part3.name = "Siège conducteur"
        part3.price = 248.95
        repair.addToParts(part3)
        newAction2.repair = repair
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CarLog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
