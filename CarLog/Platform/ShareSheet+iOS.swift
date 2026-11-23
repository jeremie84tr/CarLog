//
//  ShareSheet+iOS.swift
//  CarLog
//

#if os(iOS)
import UIKit

extension ShareSheet {
    /// UIActivityViewController, avec ancrage popover pour iPad.
    @MainActor
    static func presentNative(_ url: URL, cleaning cleanup: [URL]) throws {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in removeTemporaryFiles(cleanup) }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else {
            removeTemporaryFiles(cleanup)
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
#endif
