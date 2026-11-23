//
//  ActionView.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI

struct ActionView: View {
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var action: Action
    
    @State var actionType: eActionType
    
    init(action: Action) {
        self._action = .init(wrappedValue: action)
        // Une nouvelle action (ni fuel ni repair) est un plein par défaut.
        self.actionType = action.repair != nil && action.fuel == nil ? .repair : .fuel
    }

    /// Crée le Fuel/Repair du type sélectionné s'il n'existe pas encore.
    private func ensureObjectExists(for type: eActionType) {
        switch type {
        case .fuel:
            if action.fuel == nil { action.fuel = Fuel(context: viewContext) }
        case .repair:
            if action.repair == nil { action.repair = Repair(context: viewContext) }
        }
    }
    
    enum eActionType: Hashable {
        case fuel
        case repair
    }
    
    func makeExponential(_ values: Range<Int64>, multiplier: Int64) -> [Int64] {
        return values.map{$0 * multiplier}
    }
    
    private var positiveExponential: [Int64] {
        return (0..<5).map{$0}.reduce(into: [Int64](), { partialResult, added in
            for element in makeExponential(1..<20, multiplier: Int64(pow(10, Double(added)))) {
                if !partialResult.contains(element) {
                    partialResult.append(element)
                }
            }
        })
    }
    
    var exponentialMileage: [Int64] {
        var ret = [Int64]()
        ret.append(0)
        ret.append(contentsOf: positiveExponential.map{Int64(action.mileage) - $0}.filter{$0 > 0})
        ret.append(action.mileage)
        ret.append(contentsOf: positiveExponential.map{Int64(action.mileage) + $0})
        return ret.sorted(by: {$0 < $1})
    }
    
    var body: some View {
        List {
            Section("Action") {
                MileagePicker(title: "Kilométrage", value: $action.mileage, candidates: exponentialMileage)
                TextField("Raison", text: $action.reason)
                
                DatePicker("Date", selection: $action.timestamp)
                TextField("Lieu", text: $action.location)
                
                Picker("Type d'action", selection: $actionType) {
                    Text("Carburant")
                        .tag(eActionType.fuel)
                    Text("Réparation")
                        .tag(eActionType.repair)
                }
            }
            
            switch actionType {
            case .fuel:
                if let fuel = action.fuel {
                    FuelView(fuel: fuel)
                }
            case .repair:
                if let repair = action.repair {
                    RepairView(repair: repair)
                }
            }

        }
        .onAppear { ensureObjectExists(for: actionType) }
        .onChange(of: actionType) { _, newType in ensureObjectExists(for: newType) }
        .toolbar {
            if action.repair != nil {
                ToolbarItem(placement: .platformTrailing) {
                    PlatformEditButton()
                }
                ToolbarItem {
                    Button(action: addPart) {
                        Label("Ajouter une pièce", systemImage: "plus")
                    }
                }
            }
        }
        .onDisappear {
            switch actionType {
            case .fuel:
                action.repair.map(viewContext.delete)
                action.repair = nil
            case .repair:
                action.fuel.map(viewContext.delete)
                action.fuel = nil
            }
            viewContext.saveLoggingErrors()
        }
    }
    
    private func addPart() {
        withAnimation {
            let newPart = Part(context: viewContext)
            action.repair?.addToParts(newPart)

            viewContext.saveLoggingErrors()
        }
    }
}

