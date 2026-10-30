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
            
            ForEach(sortedParts) { part in
                PartView(part: part)
            }
            .onDelete(perform: deleteParts)
        }
    }

    /// Même ordre pour l'affichage et la suppression (l'ordre d'un NSSet n'est pas garanti).
    /// Tri sur l'identifiant, stable pendant la saisie (contrairement à un tri par nom).
    private var sortedParts: [Part] {
        ((repair.parts?.allObjects as? [Part]) ?? []).sorted {
            $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
        }
    }

    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            let parts = sortedParts
            offsets.map { parts[$0] }.forEach(viewContext.delete)

            viewContext.saveLoggingErrors()
        }
    }
}
