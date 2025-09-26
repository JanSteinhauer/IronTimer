//
//  RunDetailView.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 26.09.25.
//

import SwiftUI
import SwiftData
import MapKit
import UniformTypeIdentifiers


struct GPXDocument: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .xml) { $0.data }
    }
}

struct RunDetailView: View {
    let run: Run
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Map
                GroupBox("Route") {
                    Map(position: $mapPosition) {
                        if run.route.count >= 2 {
                            let coords = run.route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                            MapPolyline(coordinates: coords).stroke(.blue, lineWidth: 3)
                            if let last = coords.last {
                                Annotation("End", coordinate: last) { Circle().fill(.blue).frame(width: 10, height: 10) }
                            }
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .task {
                        if let first = run.route.first {
                            mapPosition = .region(MKCoordinateRegion(center: first.coordinate,
                                                                     span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
                        }
                    }
                }

                // Summary
                GroupBox("Summary") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date: \(dateString(run.dateStart))")
                        Text("Type: \(run.type.rawValue.capitalized)")
                        Text("Feeling: \(run.feeling.rawValue.capitalized)")
                        Text("Distance: \(distanceString(run))")
                        Text("Duration: \(formatDuration(run.totalDurationSeconds))")
                        Text("Avg Pace: \(paceString(run))")
                        if !run.notes.isEmpty { Text("Notes: \(run.notes)") }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Splits
                GroupBox(run.unitIsMetric ? "Splits (per km)" : "Splits (per mile)") {
                    if run.splits.isEmpty {
                        Text("No splits").foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(run.splits) { s in
                                let p = run.unitIsMetric ? s.paceSecPerKm : s.paceSecPerMile
                                HStack {
                                    Text("\(s.index).")
                                    Spacer()
                                    Text("\(formatDuration(p ?? 0))/\(run.unitIsMetric ? "km" : "mi")")
                                        .monospaced()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Run Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: CSVDocument(data: csvData(for: run)),
                              preview: SharePreview("Run-\(dateFileName(run.dateStart)).csv")) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    ShareLink(item: GPXDocument(data: gpxData(for: run)),
                              preview: SharePreview("Run-\(dateFileName(run.dateStart)).gpx")) {
                        Label("Export GPX", systemImage: "square.and.arrow.up.on.square")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Formatting

    private func dateString(_ d: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeZone = .current; return df.string(from: d)
    }
    private func dateFileName(_ d: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd-HHmm"; df.timeZone = .current; return df.string(from: d)
    }
    private func distanceString(_ r: Run) -> String {
        r.unitIsMetric
            ? String(format: "%.2f km", r.totalDistanceMeters / 1000.0)
            : String(format: "%.2f mi", r.totalDistanceMeters / 1609.344)
    }
    private func paceString(_ r: Run) -> String {
        let p = r.unitIsMetric ? r.avgPaceSecondsPerKm : r.avgPaceSecondsPerMile
        guard let p else { return "--:--/\(r.unitIsMetric ? "km" : "mi")" }
        return "\(formatDuration(p))/\(r.unitIsMetric ? "km" : "mi")"
    }
    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                     : String(format: "%d:%02d", m, sec)
    }

    // MARK: - CSV Export

    private func csvData(for run: Run) -> Data {
        var rows: [String] = ["timestamp,lat,lon,alt_m"]
        for p in run.route {
            let ts = ISO8601DateFormatter().string(from: p.timestamp)
            let alt = p.altitude ?? 0
            rows.append("\(ts),\(p.latitude),\(p.longitude),\(alt)")
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - GPX Export

    private func gpxData(for run: Run) -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="IronTimer" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>IronTimer Run \(dateFileName(run.dateStart))</name>
            <trkseg>
        """
        let iso = ISO8601DateFormatter()
        for p in run.route {
            let time = iso.string(from: p.timestamp)
            let ele = p.altitude ?? 0
            xml += """
                  <trkpt lat="\(p.latitude)" lon="\(p.longitude)">
                    <ele>\(ele)</ele>
                    <time>\(time)</time>
                  </trkpt>
            """
        }
        xml += """
            </trkseg>
          </trk>
        </gpx>
        """
        return xml.data(using: .utf8) ?? Data()
    }
}
