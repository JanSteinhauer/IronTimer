//
//  Models.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData
import Combine


@Model
final class Exercise {
    @Attribute(.unique) var name: String
    var primaryGroup: String
    var notes: String

    init(name: String, primaryGroup: String = "", notes: String = "") {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.primaryGroup = primaryGroup
        self.notes = notes
    }
}

@Model
final class SetRecord {
    var reps: Int
    var weight: Double // in kg
    var createdAt: Date

    init(reps: Int, weight: Double, createdAt: Date = .now) {
        self.reps = reps
        self.weight = weight
        self.createdAt = createdAt
    }
}

@Model
final class WorkoutItem {
    // One exercise performed within a workout
    var exercise: Exercise
    var sets: [SetRecord]

    init(exercise: Exercise, sets: [SetRecord] = []) {
        self.exercise = exercise
        self.sets = sets
    }
}

@Model
final class Workout {
    @Attribute(.unique) var yyyymmdd: String // day key (e.g., 2025-09-13)
    var date: Date
    var items: [WorkoutItem]

    init(date: Date = .now, items: [WorkoutItem] = []) {
        let key = Self.key(from: date)
        self.yyyymmdd = key
        self.date = Calendar.current.startOfDay(for: date)
        self.items = items
    }

    static func key(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}
