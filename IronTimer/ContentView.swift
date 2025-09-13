//
//  ContentView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayWorkoutView()
                .tabItem {
                    Label("Today", systemImage: "dumbbell")
                }

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "list.bullet.rectangle")
                }

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.xyaxis.line")
                }
        }
        .tint(.ironOrange)    }
}
