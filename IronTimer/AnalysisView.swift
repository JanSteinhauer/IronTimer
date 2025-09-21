//
//  AnalysisView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

// MARK: - Transferable CSV
struct CSVDocument: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { $0.data }
    }
}

struct AnalysisView: View {
    @Query(sort: [SortDescriptor(\Workout.date, order: .forward)]) private var workouts: [Workout]
    @Query(sort: [SortDescriptor(\Exercise.name, order: .forward)]) private var exercises: [Exercise]

    @State private var selectedExercise: Exercise? = nil
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Exercise Picker
                    GroupBox("Exercise") {
                        VStack(spacing: 8) {
                            if exercises.isEmpty {
                                Text("No exercises yet").foregroundStyle(.secondary)
                            } else {
                                Picker("Exercise", selection: $selectedExercise) {
                                    Text("All Exercises").tag(Optional<Exercise>.none)
                                    ForEach(filteredExercises) { ex in
                                        Text(ex.name).tag(Optional(ex))
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic))
                            }
                        }
                    }

                    // Progression charts (require some data)
                    GroupBox("Heaviest Weight per Day") {
                        if exerciseAggs.isEmpty {
                            EmptyMini()
                        } else {
                            if let domain = xDomain {
                                Chart(exerciseAggs) { d in
                                    LineMark(
                                        x: .value("Date", d.date),
                                        y: .value("Max Weight (kg)", d.maxWeight)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle())
                                }
                                .chartXScale(domain: domain)
                                .frame(height: 220)
                            } else {
                                Chart(exerciseAggs) { d in
                                    LineMark(
                                        x: .value("Date", d.date),
                                        y: .value("Max Weight (kg)", d.maxWeight)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle())
                                }
                                .frame(height: 220)
                            }
                        }
                    }

                    GroupBox("Total Reps per Day") {
                        if exerciseAggs.isEmpty {
                            EmptyMini()
                        } else {
                            if let domain = xDomain {
                                Chart(exerciseAggs) { d in
                                    BarMark(
                                        x: .value("Date", d.date),
                                        y: .value("Reps", d.totalReps)
                                    )
                                }
                                .chartXScale(domain: domain)
                                .frame(height: 220)
                            } else {
                                Chart(exerciseAggs) { d in
                                    BarMark(
                                        x: .value("Date", d.date),
                                        y: .value("Reps", d.totalReps)
                                    )
                                }
                                .frame(height: 220)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: CSVDocument(data: generateCSV(for: selectedExercise)),
                        preview: SharePreview("IronTimer Export.csv")
                    ) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export CSV")
                }
            }
        }
    }

    // MARK: - Filtering

    private var filteredExercises: [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    // MARK: - Aggregation

    private struct ExerciseDayAgg: Identifiable {
        var id: String { key }
        let key: String           // yyyy-MM-dd
        let date: Date
        let maxWeight: Double     // heaviest set weight that day
        let totalReps: Int        // sum of reps that day (all sets)
    }

    private var exerciseAggs: [ExerciseDayAgg] {
        // If an exercise is selected, limit to it; else use all items merged by day
        var M: [String: (date: Date, maxW: Double, reps: Int)] = [:]
        let cal = Calendar.current

        for w in workouts {
            let day = cal.startOfDay(for: w.date)
            let key = Workout.key(from: day)

            // Filter items by selected exercise if any
            let items = w.items.filter { it in
                guard let sel = selectedExercise else { return true }
                return it.exercise.name.caseInsensitiveCompare(sel.name) == .orderedSame
            }

            guard !items.isEmpty else { continue }

            var localMaxW: Double = 0
            var localReps = 0
            for it in items {
                for s in it.sets {
                    localMaxW = max(localMaxW, s.weight)
                    localReps += s.reps
                }
            }
            let prev = M[key] ?? (day, 0, 0)
            // Merge by day: keep the heaviest weight of the day; sum reps
            M[key] = (day, max(prev.maxW, localMaxW), prev.reps + localReps)
        }

        return M.values
            .map { ExerciseDayAgg(key: Workout.key(from: $0.date), date: $0.date, maxWeight: $0.maxW, totalReps: $0.reps) }
            .sorted { $0.date < $1.date }
    }

    private var xDomain: ClosedRange<Date>? {
        guard let first = exerciseAggs.first?.date, let last = exerciseAggs.last?.date else { return nil }
        return first ... last
    }

    // MARK: - CSV Export (filtered if exercise selected)

    private func generateCSV(for exercise: Exercise?) -> Data {
        var rows: [String] = []
        rows.append("date,exercise,set_index,reps,weight_kg,volume_kg")

        let cal = Calendar.current
        let selName = exercise?.name

        for w in workouts.sorted(by: { $0.date < $1.date }) {
            let day = cal.startOfDay(for: w.date)
            let dateStr = Workout.key(from: day)

            for item in w.items {
                if let selName, item.exercise.name.caseInsensitiveCompare(selName) != .orderedSame {
                    continue
                }
                let ex = csvEscape(item.exercise.name)
                for (idx, s) in item.sets.enumerated() {
                    let volume = s.weight * Double(s.reps)
                    rows.append("\(dateStr),\(ex),\(idx+1),\(s.reps),\(clean(s.weight)),\(clean(volume))")
                }
            }
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    private func csvEscape(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return text
    }

    private func clean(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Tiny Empty State used inside GroupBoxes
private struct EmptyMini: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis").font(.title3).foregroundStyle(.secondary)
            Text("No data yet").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}
