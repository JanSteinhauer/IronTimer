//
//  TodayWorkoutView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import _SwiftData_SwiftUI

struct TodayWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Workout.date, order: .reverse)]) private var allWorkouts: [Workout]
    @Query(sort: [SortDescriptor(\Exercise.name, order: .forward)]) private var catalog: [Exercise]

    @State private var todayWorkout: Workout? = nil
    @State private var showAddExercise = false

    var body: some View {
        NavigationStack {
            List {
                if let workout = todayWorkout {
                    if workout.items.isEmpty {
                        ContentUnavailableView(
                            "No exercises today",
                            systemImage: "dumbbell",
                            description: Text("Tap the + to add your first exercise."))
                    } else {
                        ForEach(workout.items) { item in
                            WorkoutItemRow(item: item)
                        }
                        .onDelete { indexSet in
                            guard var w = todayWorkout else { return }
                            w.items.remove(atOffsets: indexSet)
                        }
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Today")
            .toolbar { EditButton() }
            .overlay(alignment: .bottomLeading) {
                AddFloatingButton(action: { showAddExercise = true })
                    .padding(.bottom, 12)
                    .padding(.leading, 12)
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet(
                    onPick: { exercise in
                        addExerciseToToday(exercise)
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear(perform: ensureToday)
        }
    }

    private func ensureToday() {
        let key = Workout.key(from: Date())
        if let found = allWorkouts.first(where: { $0.yyyymmdd == key }) {
            todayWorkout = found
            return
        }
        // Create today's workout lazily if not present
        let new = Workout(date: .now)
        context.insert(new)
        try? context.save()
        todayWorkout = new
    }

    private func addExerciseToToday(_ ex: Exercise) {
        guard let w = todayWorkout else { return }
        let item = WorkoutItem(exercise: ex)
        w.items.append(item)
        simpleHaptic()
        try? context.save()
    }
}
