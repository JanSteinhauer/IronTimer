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
                                    HStack {
                                        Text(item.exercise.name)
                                        Spacer()
                                        Text("\(totalReps(in: item)) reps")
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(item.exercise.name), \(totalReps(in: item)) reps")
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

    // MARK: - Helpers
    private func totalReps(in item: WorkoutItem) -> Int {
        item.sets.reduce(0) { $0 + $1.reps }
    }

    private func dateString(for date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}
