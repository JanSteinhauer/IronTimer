//
//  IronTimerApp.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData

@main
struct IronTimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.ironOrange)
        }
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutItem.self, SetRecord.self])
    }
}
