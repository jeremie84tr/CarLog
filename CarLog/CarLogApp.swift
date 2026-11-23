//
//  CarLogApp.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI

@main
struct CarLogApp: App {
    let persistenceController: PersistenceController = {
        #if DEBUG
        if CaptureSupport.actif { return MainActor.assumeIsolated { CaptureSupport.controller } }
        #endif
        return PersistenceController.shared
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if CaptureSupport.actif { CaptureSupport.racine() } else { ContentView() }
                #else
                ContentView()
                #endif
            }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
