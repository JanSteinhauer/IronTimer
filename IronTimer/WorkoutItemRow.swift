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
    @State private var showAddSet = false

    let item: WorkoutItem

    var totalReps: Int { item.sets.reduce(0) { $0 + $1.reps } }
    var totalVolume: Double { item.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.exercise.name)
                    .font(.headline)
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
                .contentMargins(.leading, 0, for: .scrollContent)
            }

            HStack {
                Button {
                    showAddSet = true
                } label: {
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
            AddSetSheet { reps, weight in
                let set = SetRecord(reps: reps, weight: weight)
                item.sets.append(set)
                simpleHaptic()
                try? context.save()
            }
            .presentationDetents([.height(260)])
        }
    }
}
