//
//  ContentView.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI
import Charts
import CoreData
import UniformTypeIdentifiers
import Compression
import ZIPFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Action.timestamp_, ascending: false)],
        animation: .default)
    private var actions: FetchedResults<Action>

    @ViewBuilder
    var graphiqueDepenses: some View {
        Chart {
            
            ForEach(actions) { action in
                BarMark(x: .value("Date", action.timestamp), yStart: .value("Valeur", 0), yEnd: .value("Valeur", action.price))
                .foregroundStyle(by: .value("Série", "€ dépensé"))
            }
            
            // Prix dépensé
            ForEach(actions.sorted(by: {$0.timestamp < $1.timestamp}).reduce(into: [(date: Date, accumulatedValue: Double)](), { partialResult, added in
                let last = partialResult.last?.accumulatedValue ?? 0
                partialResult.append((date: added.timestamp, accumulatedValue: last + added.price))
            }), id:\.date) { element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Valeur", element.accumulatedValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(by: .value("Accumulated", "€ cumulés"))
            }
            
            // Prix dépensé carburant
            ForEach(actions.filter{$0.fuel != nil}.sorted(by: {$0.timestamp < $1.timestamp}).reduce(into: [(date: Date, accumulatedValue: Double)](), { partialResult, added in
                let last = partialResult.last?.accumulatedValue ?? 0
                partialResult.append((date: added.timestamp, accumulatedValue: last + added.price))
            }), id:\.date) { element in
                LineMark(
                    x: .value("Date", element.date),
                    y: .value("Valeur", element.accumulatedValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(by: .value("Accumulated Fuel", "€ carburant"))
            }
            
            // Prix dépensé
            ForEach(actions.filter{$0.repair != nil}.sorted(by: {$0.timestamp < $1.timestamp}).reduce(into: [(date: Date, accumulatedValue: Double)](), { partialResult, added in
                let last = partialResult.last?.accumulatedValue ?? 0
                partialResult.append((date: added.timestamp, accumulatedValue: last + added.price))
            }), id:\.date) { element in
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
        NavigationView {
            List {
                Section("Graphiques") {
                    NavigationLink {
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
                                            if let action = fuel.action {
                                                LineMark(
                                                    x: .value("Date", action.timestamp),
                                                    y: .value("Valeur", fuel.eurosPerLiter)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(by: .value("Série", "€/L"))
                                            }
                                        }
                                        
                                        RuleMark(y: .value("Moyenne", meanFuelPrice))
                                    }
                                    .frame(height: 150)
                                    
                                    LabeledContent("Prix moyen du carburant") {
                                        Text("\(meanFuelPrice) €/L")
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
                                        ForEach(fuelActions, id: \.date) { item in
                                            if let fuel = item.value.fuelConsumption(viewContext) {
                                                LineMark(
                                                    x: .value("Date", item.date),
                                                    y: .value("Valeur", fuel)
                                                )
                                                .interpolationMethod(.catmullRom)
                                                .foregroundStyle(by: .value("Série", "Conso L/100km"))
                                            }
                                        }
                                        
                                    }
                                    .frame(height: 150)
                                    let consumedFuel = fuelActions.reduce(0, {$0 + $1.value.quantity})
                                    LabeledContent("Litres consommés") {
                                        Text("\(consumedFuel)L")
                                    }
                                    LabeledContent("Consommation moyenne globale") {
                                        Text("\(consumedFuel / (Double(distanceRan) / 100)) L/100 km")
                                    }
                                    
                                    
                                }
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            graphiqueDepenses
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
                Section("Dépenses") {
                    ForEach(actions) { action in
                        NavigationLink {
                            ActionView(action: action)
                        } label: {
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
                                                if let conso = fuel.fuelConsumption(viewContext) {
                                                    Text("\(conso) L/100Km")
                                                    Spacer()
                                                }
                                                Text("\(fuel.eurosPerLiter) €/L")
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
                    .onDelete(perform: deleteActions)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: shareActionJSON) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addAction) {
                        Label("Ajouter une action", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: shareAllZip) {
                        Label("Exporter CSV (ZIP)", systemImage: "archivebox")
                    }
                }
            }
            Text("Sélectionnez une action")
        }
    }
    
    private func shareAllZip() {
        // 1) Préparer dossier temporaire d’export
        let exportFolder = FileManager.default.temporaryDirectory.appendingPathComponent("CarLog_Export_\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)
        } catch {
            return
        }
        
        // 2) Helpers
        func csvEscaped(_ value: String) -> String {
            // Échappe les guillemets et force l’encapsulation si nécessaire
            var needsQuotes = false
            var v = value
            if v.contains("\"") {
                v = v.replacingOccurrences(of: "\"", with: "\"\"")
                needsQuotes = true
            }
            if v.contains(",") || v.contains("\n") || v.contains("\r") {
                needsQuotes = true
            }
            return needsQuotes ? "\"\(v)\"" : v
        }
        func writeFile(named name: String, contents: String) -> URL? {
            let url = exportFolder.appendingPathComponent(name)
            do {
                try contents.data(using: .utf8)?.write(to: url, options: .atomic)
                return url
            } catch {
                return nil
            }
        }
        func idString(for object: NSManagedObject?) -> String {
            guard let object else { return "" }
            return object.objectID.uriRepresentation().absoluteString
        }
        
        // 3) Construire CSVs
        // actions.csv
        var actionsCSV = "id,timestamp_iso8601,mileage,location,reason,price,fuel_id,repair_id\n"
        let iso = ISO8601DateFormatter()
        for action in actions {
            let id = idString(for: action)
            let ts = iso.string(from: action.timestamp)
            let mileage = String(action.mileage)
            let location = csvEscaped(action.location)
            let reason = csvEscaped(action.reason)
            let price = String(action.price)
            let fuelID = idString(for: action.fuel)
            let repairID = idString(for: action.repair)
            actionsCSV += "\(id),\(ts),\(mileage),\(location),\(reason),\(price),\(fuelID),\(repairID)\n"
        }
        
        // fuels.csv
        var fuelsCSV = "id,action_id,full,price,quantity,euros_per_liter\n"
        let fuels: [Fuel] = actions.compactMap { $0.fuel }
        for fuel in fuels {
            let id = idString(for: fuel)
            let actionID = idString(for: fuel.action)
            let full = fuel.full ? "true" : "false"
            let price = String(fuel.price)
            let quantity = String(fuel.quantity)
            let epl = String(fuel.eurosPerLiter)
            fuelsCSV += "\(id),\(actionID),\(full),\(price),\(quantity),\(epl)\n"
        }
        
        // repairs.csv
        var repairsCSV = "id,action_id,price,total_price\n"
        let repairs: [Repair] = actions.compactMap { $0.repair }
        for repair in repairs {
            let id = idString(for: repair)
            let actionID = idString(for: repair.action)
            let price = String(repair.price)
            let total = String(repair.totalPrice)
            repairsCSV += "\(id),\(actionID),\(price),\(total)\n"
        }
        
        // parts.csv
        var partsCSV = "id,repair_id,name,price\n"
        let allParts: [Part] = repairs.flatMap { ($0.parts?.allObjects as? [Part]) ?? [] }
        for part in allParts {
            let id = idString(for: part)
            let repairID = idString(for: part.repair)
            let name = csvEscaped(part.name)
            let price = String(part.price)
            partsCSV += "\(id),\(repairID),\(name),\(price)\n"
        }
        
        // 4) index.json
        struct Index: Codable {
            let exportedAt: Date
            let schemaVersion: Int
            let counts: Counts
            struct Counts: Codable {
                let actions: Int
                let fuels: Int
                let repairs: Int
                let parts: Int
            }
        }
        let index = Index(exportedAt: .now,
                          schemaVersion: 1,
                          counts: .init(actions: actions.count,
                                        fuels: fuels.count,
                                        repairs: repairs.count,
                                        parts: allParts.count))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let indexData = try? encoder.encode(index),
              let indexString = String(data: indexData, encoding: .utf8) else {
            return
        }
        
        // 5) Écrire fichiers
        guard writeFile(named: "actions.csv", contents: actionsCSV) != nil,
              writeFile(named: "fuels.csv", contents: fuelsCSV) != nil,
              writeFile(named: "repairs.csv", contents: repairsCSV) != nil,
              writeFile(named: "parts.csv", contents: partsCSV) != nil,
              writeFile(named: "index.json", contents: indexString) != nil else {
            return
        }
        
        // 6) Créer ZIP
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("CarLog_Export_\(ISO8601DateFormatter().string(from: .now)).zip")
        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            return
        }
        do {
            let fileNames = ["index.json", "actions.csv", "fuels.csv", "repairs.csv", "parts.csv"]
            for name in fileNames {
                let fileURL = exportFolder.appendingPathComponent(name)
                try archive.addEntry(with: name, fileURL: fileURL, compressionMethod: .deflate)
            }
        } catch {
            return
        }
        
        // 7) Partager
        let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
    
    private func shareActionJSON() {
        // 1) Construire des DTO codables
        struct PartDTO: Codable {
            let name: String
            let price: Double
        }
        struct RepairDTO: Codable {
            let price: Double
            let totalPrice: Double
            let parts: [PartDTO]
        }
        struct FuelDTO: Codable {
            let full: Bool
            let price: Double
            let quantity: Double
            let eurosPerLiter: Double
        }
        struct ActionDTO: Codable {
            let timestamp: Date
            let mileage: Int64
            let location: String
            let reason: String
            let price: Double
            let fuel: FuelDTO?
            let repair: RepairDTO?
        }
        struct ExportDTO: Codable {
            let exportedAt: Date
            let actions: [ActionDTO]
        }
        
        // 2) Mapper Core Data -> DTO
        let mapped: [ActionDTO] = actions.map { action in
            let fuelDTO: FuelDTO? = {
                guard let fuel = action.fuel else { return nil }
                return FuelDTO(full: fuel.full,
                               price: fuel.price,
                               quantity: fuel.quantity,
                               eurosPerLiter: fuel.eurosPerLiter)
            }()
            let repairDTO: RepairDTO? = {
                guard let repair = action.repair else { return nil }
                let parts = (repair.parts?.allObjects as? [Part] ?? [])
                    .map { PartDTO(name: $0.name, price: $0.price) }
                return RepairDTO(price: repair.price,
                                 totalPrice: repair.totalPrice,
                                 parts: parts)
            }()
            return ActionDTO(timestamp: action.timestamp,
                             mileage: action.mileage,
                             location: action.location,
                             reason: action.reason,
                             price: action.price,
                             fuel: fuelDTO,
                             repair: repairDTO)
        }
        
        let export = ExportDTO(exportedAt: .now, actions: mapped)
        
        // 3) Encoder en JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(export) else {
            return
        }
        
        // 4) Écrire dans un fichier temporaire .json
        let filename = "CarLog_Actions_\(ISO8601DateFormatter().string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }
        
        // 5) Partager via ShareLink (iOS 16+)
        // On utilise une UIActivityViewController via UIApplication pour compat max si besoin.
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }

    private func addAction() {
        withAnimation {
            let newAction = Action(context: viewContext)
            newAction.timestamp = Date()
            newAction.mileage = actions.max(by: {$0.mileage < $1.mileage})?.mileage ?? 0

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteActions(offsets: IndexSet) {
        withAnimation {
            offsets.map { actions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

extension Collection where Element == Action {
    var totalExpenses: Double {
        self.reduce(0.0) { partialResult, element in
            if let fuel = element.fuel {
                return partialResult + fuel.price
            } else if let repair = element.repair {
                return partialResult + repair.totalPrice
            }
            return partialResult
        }
    }
}

extension Fuel {
    var quantityString: String {
        get {
            "\(quantity)L"
        }
    }
    var eurosPerLiter: Double {
        get {
            return price / quantity
        }
    }
}

extension Repair {
    var totalPrice: Double {
        get {
            if let parts = parts?.allObjects as? [Part] {
                return price + parts.reduce(0.0, {$0 + $1.price})
            }
            return price
        }
    }
}

private let actionTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    
    return formatter
}()

protocol ExpressibleAsDouble {
    var double: Double { get }
}

extension Double: ExpressibleAsDouble {
    var double: Double { self }
}

extension Float: ExpressibleAsDouble {
    var double: Double { Double(self) }
}

extension Int: ExpressibleAsDouble {
    var double: Double { Double(self) }
}

enum eStat {
    case mean
    case sum
    case cumulative(Double)
    static var Q1: eStat {.cumulative(0.25)}
    static var med: eStat {.cumulative(0.5)}
    static var Q3: eStat {.cumulative(0.75)}
    
    func compute<N: ExpressibleAsDouble & Comparable>(on data: [N]) -> Double {
        switch self {
        case .mean:
            if data.count > 0 {
                return Double(Self.sum.compute(on: data)) / Double(data.count)
            }
            return 0
        case .sum:
            return data.reduce(0.0, {$0 + $1.double})
        case .cumulative(let percentage):
            let ordered = data.sorted(by: {$0 < $1})
            let count = data.count
            
            let index = Int((Double(count) * percentage).rounded(.down))
            
            return Double(ordered[index].double)
        }
    }
}

extension Collection where Element: ExpressibleAsDouble & Comparable {
    
    func statistics(using function: eStat) -> Double {
        function.compute(on: self.map{$0})
    }
    
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

