//
//  StatisticsView.swift
//  CarLog
//

import SwiftUI
import Charts
import CoreData

/// Détail des graphiques : kilométrage, prix du carburant et consommation.
struct StatisticsView: View {
    let actions: [Action]

    var body: some View {
        let consumptions = actions.fuelConsumptions
        if let last = actions.last, let first = actions.first {
            let distanceRan = Int(first.mileage) - Int(last.mileage)
            List {
                Section("Général") {
                    Chart {
                        // Kilométrage
                        ForEach(actions) { action in
                            LineMark(
                                x: .value("Date", action.timestamp),
                                y: .value("Valeur", action.mileage)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(by: .value("Série", "Kilométrage"))
                        }
                        
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 150)
                    
                    LabeledContent("Kilomètres parcourus") {
                        Text("\(distanceRan) km")
                    }
                    
                    let meanFuelPrice = actions.compactMap{$0.fuel?.eurosPerLiter}.statistics(using: .mean)
                    Chart {
                        
                        // Prix carburant
                        ForEach(actions.compactMap{$0.fuel}) { fuel in
                            if let action = fuel.action, let eurosPerLiter = fuel.eurosPerLiter {
                                LineMark(
                                    x: .value("Date", action.timestamp),
                                    y: .value("Valeur", eurosPerLiter)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(by: .value("Série", "€/L"))
                            }
                        }
                        
                        RuleMark(y: .value("Moyenne", meanFuelPrice))
                    }
                    .frame(height: 150)
                    
                    LabeledContent("Prix moyen du carburant") {
                        Text("\(meanFuelPrice.pricePerLiterString) €/L")
                    }
                }
                
                let fuelActions: [(date: Date, value: Fuel)] = actions.compactMap({ action in
                    guard let fuel = action.fuel else {
                        return nil
                    }
                    return (date: action.timestamp, value: fuel)
                })
                Section("Consommation") {
                    Chart {
                        // Consommation L/100km
                        ForEach(Array(actions.filter { consumptions[$0.objectID] != nil }.enumerated()), id: \.offset) { _, action in
                            if let consumption = consumptions[action.objectID] {
                                LineMark(
                                    x: .value("Date", action.timestamp),
                                    y: .value("Valeur", consumption)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(by: .value("Série", "Conso L/100km"))
                            }
                        }
                        
                    }
                    .frame(height: 150)
                    let consumedFuel = fuelActions.reduce(0, {$0 + $1.value.quantity})
                    LabeledContent("Litres consommés") {
                        Text("\(consumedFuel.shortNumber) L")
                    }
                    LabeledContent("Consommation moyenne globale") {
                        if distanceRan > 0 {
                            Text("\((consumedFuel / (Double(distanceRan) / 100)).shortNumber) L/100 km")
                        } else {
                            Text("–")
                        }
                    }
                    
                    
                }
            }
        }
    }
}
