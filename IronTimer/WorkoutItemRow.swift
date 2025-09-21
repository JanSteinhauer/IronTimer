//
//  WorkoutItemRow.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData

struct WorkoutItemRow: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)]) private var allWorkouts: [Workout]

    @State private var showAddSet = false
    let item: WorkoutItem

    var totalReps: Int { item.sets.reduce(0) { $0 + $1.reps } }
    var totalVolume: Double { item.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.exercise.name).font(.headline)
                Spacer()
                if totalReps > 0 {
                    Text("\(totalReps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !item.sets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.sets) { s in
                            SetBadge(reps: s.reps, weight: s.weight)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack {
                Button { showAddSet = true } label: {
                    Label("Add Set", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.ironOrange)

                Spacer()

                if totalVolume > 0 {
                    Text("Vol: \(Int(totalVolume)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAddSet) {
            let suggestion = lastSetSuggestion(for: item.exercise)
            AddSetSheet(
                initialReps: suggestion?.reps,
                initialWeight: suggestion?.weight
            ) { reps, weight in
                let set = SetRecord(reps: reps, weight: weight)
                item.sets.append(set)
                simpleHaptic()
                try? context.save()
            }
            .presentationDetents([.height(260)])
        }
    }

    /// Find the most recent set logged for this exercise across all workouts.
    private func lastSetSuggestion(for exercise: Exercise) -> (reps: Int, weight: Double)? {
        // Search newest → oldest
        for w in allWorkouts {
            // Look for the same exercise in this workout
            if let it = w.items.first(where: { $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame }) {
                // Prefer the latest by createdAt if available; else last in array
                if let latest = it.sets.max(by: { $0.createdAt < $1.createdAt }) ?? it.sets.last {
                    return (latest.reps, latest.weight)
                }
            }
        }
        return nil
    }
}
