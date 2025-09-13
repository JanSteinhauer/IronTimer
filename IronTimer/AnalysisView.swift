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

// MARK: - Analysis
struct AnalysisView: View {
    @Query(sort: [SortDescriptor(\Workout.date, order: .forward)]) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 1) Volume over time
                    GroupBox("Training Volume (kg) over Time") {
                        if dayAggs.isEmpty {
                            EmptyMini()
                        } else {
                            if let domain = xDomain {
                                Chart(dayAggs) { d in
                                    LineMark(
                                        x: .value("Date", d.date),
                                        y: .value("Volume (kg)", d.volume)
                                    )
                                }
                                .chartXScale(domain: domain)
                                .frame(height: 220)
                            } else {
                                Text("No data yet").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // 2) Reps per day
                    GroupBox("Total Reps per Day") {
                        if dayAggs.isEmpty {
                            EmptyMini()
                        } else {
                            if let domain = xDomain {
                                Chart(dayAggs) { d in
                                    BarMark(
                                        x: .value("Date", d.date),
                                        y: .value("Reps", d.reps)
                                    )
                                }
                                .chartXScale(domain: domain)
                                .frame(height: 220)
                            } else {
                                Text("No data yet").foregroundStyle(.secondary)
                            }
                            
                        }
                    }

                    // 3) Top exercises by volume (all time)
                    GroupBox("Top 5 Exercises by Volume (All Time)") {
                        if topExercises.isEmpty {
                            EmptyMini()
                        } else {
                            Chart(topExercises) { e in
                                BarMark(
                                    x: .value("Volume (kg)", e.volume),
                                    y: .value("Exercise", e.name)
                                )
                            }
                            .frame(height: 220)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Generate CSV on tap and share
                    ShareLink(
                        item: CSVDocument(data: generateCSV()),
                        preview: SharePreview("IronTimer Export.csv")
                    ) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Aggregations

    private struct DayAgg: Identifiable, Hashable {
        var id: String { key }            // yyyy-MM-dd
        let key: String
        let date: Date
        let volume: Double
        let reps: Int
    }

    private var dayAggs: [DayAgg] {
        var m: [String: (date: Date, volume: Double, reps: Int)] = [:]
        let cal = Calendar.current

        for w in workouts {
            let day = cal.startOfDay(for: w.date)
            let key = Workout.key(from: day)
            var vol = 0.0
            var r = 0
            for item in w.items {
                for s in item.sets {
                    vol += s.weight * Double(s.reps)
                    r += s.reps
                }
            }
            let prev = m[key] ?? (day, 0, 0)
            m[key] = (day, prev.volume + vol, prev.reps + r)
        }

        return m.values
            .map { DayAgg(key: Workout.key(from: $0.date), date: $0.date, volume: $0.volume, reps: $0.reps) }
            .sorted { $0.date < $1.date }
    }

    private struct ExerciseAgg: Identifiable {
        let name: String
        let volume: Double
        var id: String { name }
    }

    private var topExercises: [ExerciseAgg] {
        var m: [String: Double] = [:]
        for w in workouts {
            for item in w.items {
                let name = item.exercise.name
                var vol = 0.0
                for s in item.sets {
                    vol += s.weight * Double(s.reps)
                }
                m[name, default: 0] += vol
            }
        }
        return m
            .map { ExerciseAgg(name: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
            .prefix(5)
            .map { $0 }
    }

    private var xDomain: ClosedRange<Date>? {
        guard let first = dayAggs.first?.date, let last = dayAggs.last?.date else { return nil }
        return first ... last
    }

    // MARK: - CSV Export

    private func generateCSV() -> Data {
        var rows: [String] = []
        rows.append("date,exercise,set_index,reps,weight_kg,volume_kg")
        let cal = Calendar.current

        for w in workouts.sorted(by: { $0.date < $1.date }) {
            let day = cal.startOfDay(for: w.date)
            let dateStr = Workout.key(from: day) // yyyy-MM-dd
            for item in w.items {
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
        // Quote if contains comma, quote or newline; double-up quotes per CSV rules
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
