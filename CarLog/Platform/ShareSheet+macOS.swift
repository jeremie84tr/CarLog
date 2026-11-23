//
//  ShareSheet+macOS.swift
//  CarLog
//

#if os(macOS)
import AppKit

extension ShareSheet {
    /// NSSharingServicePicker ancré en bas au centre de la fenêtre active.
    @MainActor
    static func presentNative(_ url: URL, cleaning cleanup: [URL]) throws {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              let view = window.contentView else {
            removeTemporaryFiles(cleanup)
            throw ExportError("Impossible d'afficher la feuille de partage.")
        }
        let coordinator = MacShareCoordinator(cleanup: cleanup)
        let picker = NSSharingServicePicker(items: [url])
        picker.delegate = coordinator
        coordinator.retain(picker)
        let rect = NSRect(x: view.bounds.midX, y: view.bounds.minY, width: 1, height: 1)
        picker.show(relativeTo: rect, of: view, preferredEdge: .minY)
    }
}

/// Reste en vie jusqu'à la fin du partage, puis supprime les fichiers temporaires.
private final class MacShareCoordinator: NSObject, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
    private let cleanup: [URL]
    private var keepAlive: [AnyObject] = []

    init(cleanup: [URL]) {
        self.cleanup = cleanup
        super.init()
        keepAlive.append(self)
    }

    func retain(_ object: AnyObject) { keepAlive.append(object) }

    private func finish() {
        ShareSheet.removeTemporaryFiles(cleanup)
        keepAlive.removeAll()
    }

    func sharingServicePicker(_ picker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        // nil : le menu a été fermé sans choix.
        if let service { service.delegate = self } else { finish() }
    }

    func sharingService(_ service: NSSharingService, didShareItems items: [Any]) { finish() }
    func sharingService(_ service: NSSharingService, didFailToShareItems items: [Any], error: Error) { finish() }
}
#endif
