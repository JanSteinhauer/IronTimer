//
//  AddExerciseSheet.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData

struct AddExerciseSheet: View {
    enum Mode: String, CaseIterable { case top = "Top 5", search = "Search", new = "New" }

    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Exercise.name, order: .forward)]) private var catalog: [Exercise]

    let onPick: (Exercise) -> Void

    @State private var mode: Mode = .top
    @State private var query: String = ""
    @State private var newName: String = ""
    @State private var newGroup: String = ""

    private let top5: [String] = ["Squat", "Bench Press", "Deadlift", "Overhead Press", "Barbell Row"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                switch mode {
                case .top:
                    List {
                        ForEach(top5, id: \.self) { (name: String) in
                            Button { selectFromName(name) } label: {
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.ironOrange)
                                }
                            }
                        }
                    }

                case .search:
                    List {
                        // @Model types are Identifiable; no need for id: \.self
                        ForEach(filteredCatalog) { ex in
                            Button { onPick(ex); dismissSelf() } label: {
                                HStack {
                                    Text(ex.name)
                                    Spacer()
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
                    .autocorrectionDisabled()

                case .new:
                    Form {
                        Section("Exercise") {
                            TextField("Name (required)", text: $newName)
                            TextField("Primary muscle group (optional)", text: $newGroup)
                        }
                        Section {
                            Button { createNew() } label: {
                                Label("Add to Catalog & Use", systemImage: "checkmark.circle.fill")
                            }
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .tint(.ironOrange)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismissSelf() }
                }
            }
        }
    }

    private var filteredCatalog: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return catalog }
        return catalog.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private func selectFromName(_ name: String) {
        if let found = catalog.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            onPick(found); dismissSelf(); return
        }
        let ex = Exercise(name: name)
        context.insert(ex)
        try? context.save()
        onPick(ex)
        dismissSelf()
    }

    private func createNew() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if let dup = catalog.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            onPick(dup); dismissSelf(); return
        }

        let ex = Exercise(name: name, primaryGroup: newGroup)
        context.insert(ex)
        try? context.save()
        onPick(ex)
        dismissSelf()
    }

    @Environment(\.dismiss) private var dismiss
    private func dismissSelf() { dismiss() }
}
