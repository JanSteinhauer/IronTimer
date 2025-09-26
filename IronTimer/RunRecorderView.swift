//
//  RunRecorderView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 26.09.25.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct RunRecorderView: View {
    @Environment(\.modelContext) private var context

    @StateObject private var recorder = RunRecorder(unitIsMetric: true) // default to km; you can toggle in UI
    @State private var selectedType: RunType = .easy
    @State private var selectedFeeling: RunFeeling = .okay
    @State private var notes: String = ""
    @State private var unitIsMetric: Bool = true

    @State private var mapPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.137, longitude: 11.575), // Munich as harmless initial
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    // Unit + Type + Feeling
                    HStack {
                        Picker("Units", selection: $unitIsMetric) {
                            Text("km").tag(true)
                            Text("miles").tag(false)
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Menu {
                            Picker("Run Type", selection: $selectedType) {
                                ForEach(RunType.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                            }
                            Picker("Feeling", selection: $selectedFeeling) {
                                ForEach(RunFeeling.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                            }
                        } label: {
                            Label("Meta", systemImage: "slider.horizontal.3")
                        }
                    }

                    // Live stats
                    GroupBox("Live") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Distance: \(formatDistance(recorder.distanceMeters, metric: unitIsMetric))")
                            Text("Duration: \(formatDuration(recorder.durationSeconds))")
                            Text("Pace: \(formatPace(distanceMeters: recorder.distanceMeters, seconds: recorder.durationSeconds, metric: unitIsMetric))")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Map route preview
                    GroupBox("Route") {
                        Map(position: $mapPosition) {
                            if recorder.route.count >= 2 {
                                let coords = recorder.route.map { $0.coordinate }
                                MapPolyline(coordinates: coords)
                                    .stroke(.blue, lineWidth: 3)
                                if let last = recorder.route.last {
                                    Annotation("You", coordinate: last.coordinate) { Circle().fill(.blue).frame(width: 10, height: 10) }
                                }
                            }
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: recorder.route.last?.coordinate.latitude) { _, lat in
                            if let lat, let coord = recorder.route.last?.coordinate {
                                withAnimation {
                                    mapPosition = .region(MKCoordinateRegion(
                                        center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    ))
                                }
                            }
                        }

                    }

                    // Splits
                    GroupBox(unitIsMetric ? "Splits (per km)" : "Splits (per mile)") {
                        if recorder.splits.isEmpty {
                            Text("No splits yet").foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(recorder.splits) { s in
                                    HStack {
                                        Text("\(s.index).")
                                        Spacer()
                                        let pace = unitIsMetric ? s.paceSecPerKm : s.paceSecPerMile
                                        Text("\(formatDuration(pace ?? 0))/\(unitIsMetric ? "km" : "mi")")
                                            .monospaced()
                                    }
                                }
                            }
                        }
                    }

                    // Notes
                    GroupBox("Notes") {
                        TextField("e.g. Run felt good", text: $notes, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                }
                .padding()
            }
            .navigationTitle(recorder.isRecording ? "Recording…" : "Run")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        recorder.requestAuthorization()
                        unitIsMetric ? () : ()
                        recorder.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .disabled(recorder.isRecording)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        recorder.stop()
                        saveRun()
                    } label: {
                        Label("Stop & Save", systemImage: "stop.fill")
                    }
                    .disabled(!recorder.isRecording)
                }
            }
            .onAppear { recorder.requestAuthorization() }
            .onChange(of: unitIsMetric) { _, new in
                // Unit switch only affects display and splits distance threshold for future runs
                // For simplicity here we just recreate recorder with new unit when not recording.
                if !recorder.isRecording {
                    // no live swap; keep simple
                }
            }
        }
    }

    private func saveRun() {
        let run = Run(
            dateStart: Date().addingTimeInterval(-recorder.durationSeconds),
            unitIsMetric: unitIsMetric,
            type: selectedType,
            feeling: selectedFeeling,
            notes: notes,
            totalDistanceMeters: recorder.distanceMeters,
            totalDurationSeconds: recorder.durationSeconds,
            route: recorder.route.map {
                RoutePoint(timestamp: $0.timestamp,
                           latitude: $0.coordinate.latitude,
                           longitude: $0.coordinate.longitude,
                           altitude: $0.altitude,
                           hAcc: $0.horizontalAccuracy)
            },
            splits: recorder.splits
        )
        context.insert(run)
        try? context.save()
    }

    // MARK: - Formatting

    private func formatDistance(_ meters: Double, metric: Bool) -> String {
        if metric {
            let km = meters / 1000.0
            return km < 10 ? String(format: "%.2f km", km) : String(format: "%.1f km", km)
        } else {
            let miles = meters / 1609.344
            return miles < 10 ? String(format: "%.2f mi", miles) : String(format: "%.1f mi", miles)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let s = Int(seconds.rounded())
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    private func formatPace(distanceMeters: Double, seconds: Double, metric: Bool) -> String {
        guard distanceMeters > 0 else { return "--:--/\(metric ? "km" : "mi")" }
        let perUnit = metric ? (seconds / (distanceMeters / 1000.0)) : (seconds / (distanceMeters / 1609.344))
        return "\(formatDuration(perUnit))/\(metric ? "km" : "mi")"
    }
}
