//
//  RepairView.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI

struct RepairView: View {
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var repair: Repair
    
    var body: some View {
        Section("Réparation") {
            TextField("Forfait facturé", value: $repair.price, format: .currency(code: "EUR"))
            
            if let parts = repair.parts?.allObjects as? [Part] {
                ForEach(parts) { part in
                    PartView(part: part)
                }
                .onDelete(perform: deleteParts)
            }
        }
    }

    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            offsets.compactMap { (repair.parts?.allObjects as? [Part])?[$0] ?? nil }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
