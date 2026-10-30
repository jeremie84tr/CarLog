//
//  ExpensesSummaryView.swift
//  CarLog
//

import SwiftUI
import Charts

/// Graphique des dépenses et totaux affichés dans le label du lien « Graphiques ».
struct ExpensesSummaryView: View {
    let actions: [Action]

    private var chart: some View {
        Chart {
            
            ForEach(actions) { action in
                BarMark(x: .value("Date", action.timestamp), yStart: .value("Valeur", 0), yEnd: .value("Valeur", action.price))
                .foregroundStyle(by: .value("Série", "€ dépensé"))
            }
            
            // Prix dépensé
            ForEach(actions.cumulativeExpenses) { element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Valeur", element.accumulatedValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(by: .value("Accumulated", "€ cumulés"))
            }

            // Prix dépensé carburant
            ForEach(actions.filter{$0.fuel != nil}.cumulativeExpenses) { element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Valeur", element.accumulatedValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(by: .value("Accumulated Fuel", "€ carburant"))
            }

            // Prix dépensé réparations
            ForEach(actions.filter{$0.repair != nil}.cumulativeExpenses) { element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Valeur", element.accumulatedValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(by: .value("Accumulated Repairs", "€ réparations"))
            }
        }
        .frame(height: 150)
    }

    var body: some View {
        VStack(alignment: .leading) {
            chart
            if let str = moneyFormatter.string(from: NSNumber(floatLiteral: actions.totalExpenses)) {
                Text("Total : \(str)")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
            }
            if let str = moneyFormatter.string(from: NSNumber(floatLiteral: actions.filter{$0.fuel != nil}.totalExpenses)) {
                Text("Carburant : \(str)")
                    .foregroundStyle(Color.accentColor.mix(with: .secondary, by: 0.33))
            }
            if let str = moneyFormatter.string(from: NSNumber(floatLiteral: actions.filter{$0.repair != nil}.totalExpenses)) {
                Text("Réparations : \(str)")
                    .foregroundStyle(Color.accentColor.mix(with: .secondary, by: 0.67))
                    .font(.caption)
            }
            if let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now) {
                let lastMonthExpenses = actions.filter {
                    Calendar.current.component(.year, from: $0.timestamp) == Calendar.current.component(.year, from: lastMonth) &&
                    Calendar.current.component(.month, from: $0.timestamp) == Calendar.current.component(.month, from: lastMonth)
                }
                if let str = moneyFormatter.string(from: NSNumber(floatLiteral: lastMonthExpenses.totalExpenses)) {
                    Text("Mois dernier : \(str)")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
        }
    }
}
