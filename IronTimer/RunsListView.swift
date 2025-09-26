//
//  RunsListView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 26.09.25.
//

import SwiftUI
import SwiftData

struct RunsListView: View {
    @Query(sort: [SortDescriptor(\Run.dateStart, order: .reverse)]) private var runs: [Run]

    var body: some View {
        NavigationStack {
            List {
                if runs.isEmpty {
                    ContentUnavailableView("No runs yet",
                                           systemImage: "figure.run.circle",
                                           description: Text("Record a run to see it here."))
                } else {
                    ForEach(runs) { run in
                        NavigationLink {
                            RunDetailView(run: run)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dateString(run.dateStart))
                                        .font(.headline)
                                    Text("\(run.type.rawValue.capitalized) • \(run.feeling.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(distanceString(run))
                                    Text(paceString(run))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Runs")
            .toolbar {
                NavigationLink {
                    RunRecorderView()
                } label: {
                    Label("Record", systemImage: "record.circle")
                }
            }
        }
    }

    private func dateString(_ d: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .medium; return df.string(from: d)
    }
    private func distanceString(_ r: Run) -> String {
        if r.unitIsMetric {
            return String(format: "%.2f km", r.totalDistanceMeters / 1000.0)
        } else {
            return String(format: "%.2f mi", r.totalDistanceMeters / 1609.344)
        }
    }
    private func paceString(_ r: Run) -> String {
        let pace = r.unitIsMetric ? r.avgPaceSecondsPerKm : r.avgPaceSecondsPerMile
        guard let p = pace else { return "--:--/\(r.unitIsMetric ? "km" : "mi")" }
        let m = Int(p) / 60; let s = Int(p) % 60
        return String(format: "%d:%02d/%@", m, s, r.unitIsMetric ? "km" : "mi")
    }
}
