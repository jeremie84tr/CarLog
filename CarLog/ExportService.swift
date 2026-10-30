//
//  ExportService.swift
//  CarLog
//

import UIKit
import CoreData
import ZIPFoundation

struct ExportError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// Génération des fichiers d'export (ZIP de CSV, JSON) à partir des actions.
enum ExportService {

    static func makeZip(from actions: [Action]) throws -> URL {
            // 1) Préparer dossier temporaire d’export
            let exportFolder = FileManager.default.temporaryDirectory.appendingPathComponent("CarLog_Export_\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)
            } catch {
                throw ExportError("Impossible de créer le dossier temporaire : \(error.localizedDescription)")
            }
            defer { try? FileManager.default.removeItem(at: exportFolder) }
            
            // 2) Helpers
            func csvEscaped(_ value: String) -> String {
                // Échappe les guillemets et force l’encapsulation si nécessaire
                var needsQuotes = false
                var v = value
                // Évite l'injection de formule à l'ouverture dans un tableur.
                if let first = v.first, "=+-@".contains(first) {
                    v = "'" + v
                }
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
            // Identifiants d'export séquentiels, cohérents entre les CSV (les objectID Core Data ne sont pas portables).
            var exportIDs = [NSManagedObjectID: String]()
            var counters = [String: Int]()
            func idString(for object: NSManagedObject?) -> String {
                guard let object else { return "" }
                if let existing = exportIDs[object.objectID] { return existing }
                let prefix = object.entity.name?.lowercased() ?? "object"
                counters[prefix, default: 0] += 1
                let id = "\(prefix)-\(counters[prefix]!)"
                exportIDs[object.objectID] = id
                return id
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
                let epl = fuel.eurosPerLiter.map { String($0) } ?? ""
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
                throw ExportError("Impossible de générer index.json.")
            }
            
            // 5) Écrire fichiers
            guard writeFile(named: "actions.csv", contents: actionsCSV) != nil,
                  writeFile(named: "fuels.csv", contents: fuelsCSV) != nil,
                  writeFile(named: "repairs.csv", contents: repairsCSV) != nil,
                  writeFile(named: "parts.csv", contents: partsCSV) != nil,
                  writeFile(named: "index.json", contents: indexString) != nil else {
                throw ExportError("Impossible d'écrire les fichiers CSV.")
            }
            
            // 6) Créer ZIP
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("CarLog_Export_\(ISO8601DateFormatter().string(from: .now)).zip")
            guard let archive = Archive(url: zipURL, accessMode: .create) else {
                throw ExportError("Impossible de créer l'archive ZIP.")
            }
            do {
                let fileNames = ["index.json", "actions.csv", "fuels.csv", "repairs.csv", "parts.csv"]
                for name in fileNames {
                    let fileURL = exportFolder.appendingPathComponent(name)
                    try archive.addEntry(with: name, fileURL: fileURL, compressionMethod: .deflate)
                }
            } catch {
                try? FileManager.default.removeItem(at: zipURL)
                throw ExportError("Impossible de remplir l'archive ZIP : \(error.localizedDescription)")
            }
        return zipURL
    }

    static func makeJSON(from actions: [Action]) throws -> URL {
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
                let eurosPerLiter: Double?
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
                throw ExportError("Impossible d'encoder les données en JSON.")
            }
            
            // 4) Écrire dans un fichier temporaire .json
            let filename = "CarLog_Actions_\(ISO8601DateFormatter().string(from: .now)).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                throw ExportError("Impossible d'écrire le fichier JSON : \(error.localizedDescription)")
            }
        return url
    }
}

enum ShareSheet {
    /// Présente la feuille de partage (avec ancrage popover pour iPad) et supprime les fichiers temporaires ensuite.
    @MainActor
    static func present(_ url: URL, cleaning cleanup: [URL]) throws {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            cleanup.forEach { try? FileManager.default.removeItem(at: $0) }
        }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else {
            cleanup.forEach { try? FileManager.default.removeItem(at: $0) }
            throw ExportError("Impossible d'afficher la feuille de partage.")
        }
        // Remonte au contrôleur actuellement présenté pour éviter un conflit de présentation.
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 1, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        presenter.present(activityVC, animated: true)
    }
}
