//
//  ShareSheet.swift
//  CarLog
//
//  Point d'entrée commun du partage de fichiers. L'implémentation propre à chaque plateforme
//  vit dans ShareSheet+iOS.swift et ShareSheet+macOS.swift (méthode `presentNative`).
//

import Foundation

enum ShareSheet {
    /// Présente la feuille de partage native et supprime les fichiers temporaires ensuite.
    @MainActor
    static func present(_ url: URL, cleaning cleanup: [URL]) throws {
        try presentNative(url, cleaning: cleanup)
    }

    static func removeTemporaryFiles(_ files: [URL]) {
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }
}
