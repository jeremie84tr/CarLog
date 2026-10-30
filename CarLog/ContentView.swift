//
//  ContentView.swift
//  CarLog
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var exportErrorMessage: String?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Action.timestamp_, ascending: false)],
        animation: .default)
    private var actions: FetchedResults<Action>

    var body: some View {
        let consumptions = actions.fuelConsumptions
        NavigationView {
            List {
                Section("Graphiques") {
                    NavigationLink {
                        StatisticsView(actions: Array(actions))
                    } label: {
                        ExpensesSummaryView(actions: Array(actions))
                    }
                }
                Section("Dépenses") {
                    ForEach(actions) { action in
                        NavigationLink {
                            ActionView(action: action)
                        } label: {
                            ActionRow(action: action, consumption: consumptions[action.objectID])
                        }
                    }
                    .onDelete(perform: deleteActions)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { export(ExportService.makeJSON) }) {
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
                    Button(action: { export(ExportService.makeZip) }) {
                        Label("Exporter CSV (ZIP)", systemImage: "archivebox")
                    }
                }
            }
            Text("Sélectionnez une action")
        }
        .alert("Export impossible",
               isPresented: Binding(get: { exportErrorMessage != nil },
                                    set: { if !$0 { exportErrorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private func export(_ make: ([Action]) throws -> URL) {
        do {
            let url = try make(Array(actions))
            try ShareSheet.present(url, cleaning: [url])
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func addAction() {
        withAnimation {
            let newAction = Action(context: viewContext)
            newAction.timestamp = Date()
            newAction.mileage = actions.max(by: {$0.mileage < $1.mileage})?.mileage ?? 0

            viewContext.saveLoggingErrors()
        }
    }

    private func deleteActions(offsets: IndexSet) {
        withAnimation {
            offsets.map { actions[$0] }.forEach(viewContext.delete)

            viewContext.saveLoggingErrors()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
