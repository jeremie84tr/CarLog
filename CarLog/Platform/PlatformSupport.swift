//
//  PlatformSupport.swift
//  CarLog
//
//  API SwiftUI neutre vis-à-vis de la plateforme. Les vues n'utilisent que ces noms ;
//  les différences iOS / macOS sont isolées ici (chaque `#if` est un point d'extension).
//

import SwiftUI

// MARK: - Barre d'outils

extension ToolbarItemPlacement {
    /// Bouton principal à gauche (partage JSON).
    static var platformLeading: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .navigation
        #endif
    }

    /// Bouton secondaire à droite (édition).
    static var platformTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .primaryAction
        #endif
    }

    /// Action secondaire en bas (barre inférieure sur iOS, barre d'outils sur macOS).
    static var platformBottom: ToolbarItemPlacement {
        #if os(iOS)
        .bottomBar
        #else
        .automatic
        #endif
    }
}

/// Bouton « Modifier » : n'existe pas sur macOS (la suppression passe par le menu contextuel / la touche ⌫).
struct PlatformEditButton: View {
    var body: some View {
        #if os(iOS)
        EditButton()
        #else
        EmptyView()
        #endif
    }
}

// MARK: - Modificateurs de vue

extension View {
    /// Clavier numérique décimal (iOS) ; sans effet sur macOS.
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Titre de navigation en mode inline (iOS) ; sans effet sur macOS.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

extension View {
    /// Navigation en pile sur iOS (captures App Store) ; style par défaut sur macOS.
    func stackNavigationViewStyle() -> some View {
        #if os(iOS)
        self.navigationViewStyle(.stack)
        #else
        self
        #endif
    }
}
