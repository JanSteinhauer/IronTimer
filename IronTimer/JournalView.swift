//  JournalView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)]) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            List {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Log your first workout on the Today page.")
                    )
                } else {
                    ForEach(workouts) { workout in
                        Section {
                            if workout.items.isEmpty {
                                Text("No exercises logged.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(workout.items) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.exercise.name)
                                            .font(.headline)

                                        // Show sets as "reps x weight"
                                        if item.sets.isEmpty {
                                            Text("No sets")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            HStack {
                                                ForEach(item.sets) { s in
                                                    Text("\(s.reps)x\(clean(s.weight))")
                                                        .font(.caption)
                                                        .padding(6)
                                                        .background(.ultraThinMaterial, in: Capsule())
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Text(dateString(for: workout.date))
                        }
                    }
                }
            }
            .navigationTitle("Journal")
        }
    }

    private func dateString(for date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    private func clean(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : String(format: "%.1f", v)
    }
}
