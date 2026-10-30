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
        self.actionType = action.fuel != nil ? .fuel : .repair
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
                Picker("Kilométrage", selection: $action.mileage) {
                    ForEach(exponentialMileage, id:\.self) { km in
                        Text("\(km) Km")
                            .tag(km)
                    }
                }.pickerStyle(.wheel)
                TextField("Raison", text: $action.reason)
                
                DatePicker("Date", selection: $action.timestamp)
                TextField("Lieu", text: $action.location)
                
                Picker("Type d'action", selection: $actionType) {
                    Text("Carburant")
                        .tag(eActionType.fuel)
                    Text("Reparation")
                        .tag(eActionType.repair)
                }
            }
            
            switch actionType {
            case .fuel:
                if let fuel = action.fuel {
                    FuelView(fuel: fuel)
                } else {
                    Spacer()
                        .onAppear {
                            action.fuel = Fuel(context: viewContext)
                        }
                }
            case .repair:
                if let repair = action.repair {
                    RepairView(repair: repair)
                } else {
                    Spacer()
                        .onAppear {
                            action.repair = Repair(context: viewContext)
                        }
                }
            }
            
        }
        .toolbar {
            if action.repair != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addPart) {
                        Label("Add Action", systemImage: "plus")
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

