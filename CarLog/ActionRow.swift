//
//  ActionRow.swift
//  CarLog
//

import SwiftUI

/// Une ligne de la liste des dépenses.
struct ActionRow: View {
    @ObservedObject var action: Action
    /// Consommation L/100 km de ce plein, si calculable.
    let consumption: Double?

    var body: some View {
            VStack {
                HStack(alignment: .top) {
                    Text(action.timestamp, formatter: actionTimestampFormatter)
                        .font(.caption)
                    Spacer()
                    Group {
                        if let fuel = action.fuel {
                            if action.reason != "" {
                                Text("\(action.reason), \(action.location)")
                            } else {
                                Text("\(fuel.full ? "Plein" : fuel.quantityString) à \(action.location)")
                            }
                        } else if action.repair != nil {
                            Text("\(action.reason) à \(action.location)")
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                }
                HStack(alignment: .bottom) {
                    Text("\(action.mileage)")
                        .font(.title2)
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let fuel = action.fuel {
                            if let str = moneyFormatter.string(from: NSNumber(floatLiteral: fuel.price)) {
                                Text(str)
                            }
                            HStack {
                                if let conso = consumption {
                                    Text("\(conso.shortNumber) L/100 km")
                                    Spacer()
                                }
                                if let eurosPerLiter = fuel.eurosPerLiter {
                                    Text("\(eurosPerLiter.pricePerLiterString) €/L")
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        } else if let repair = action.repair {
                            if let str = moneyFormatter.string(from: NSNumber(floatLiteral: repair.totalPrice)) {
                                Text(str)
                            }
                            Text("\(repair.parts?.count ?? 0) Actions effectuées")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
    }
}

private let actionTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    
    return formatter
}()
