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

            viewContext.saveLoggingErrors()
        }
    }
}
