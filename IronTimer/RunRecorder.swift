//
//  RunRecorder.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 26.09.25.
//

import Foundation
import CoreLocation
import Combine
import SwiftData

final class RunRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var durationSeconds: Double = 0
    @Published private(set) var route: [CLLocation] = []
    @Published private(set) var splits: [RunSplit] = []

    let unitIsMetric: Bool
    private let splitDistanceMeters: Double
    private var splitStartTime: Date?
    private var splitStartIndex: Int = 0
    private var accumulatedForSplit: Double = 0
    private var timer: Timer?
    private let manager = CLLocationManager()
    private var startTime: Date?

    init(unitIsMetric: Bool) {
        self.unitIsMetric = unitIsMetric
        self.splitDistanceMeters = unitIsMetric ? 1000.0 : 1609.344
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAuthorization() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func start() {
        guard !isRecording else { return }
        distanceMeters = 0
        durationSeconds = 0
        route.removeAll()
        splits.removeAll()
        accumulatedForSplit = 0
        splitStartIndex = 0
        splitStartTime = Date()
        startTime = Date()
        isRecording = true

        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.isRecording, let s = self.startTime {
                self.durationSeconds = Date().timeIntervalSince(s)
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        isRecording = false
        manager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        // close last partial split if any distance accumulated
        if accumulatedForSplit > 1, let splitStartTime {
            let elapsed = Date().timeIntervalSince(splitStartTime)
            let idx = splits.count + 1
            splits.append(RunSplit(index: idx, distanceMeters: accumulatedForSplit, durationSeconds: elapsed))
        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording else { return }
        let filtered = locations.filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 50 } // basic filter
        guard !filtered.isEmpty else { return }

        for loc in filtered {
            if let last = route.last {
                let d = loc.distance(from: last)
                if d > 0.5 { // ignore tiny jitter
                    distanceMeters += d
                    accumulatedForSplit += d
                }
                // complete splits whenever threshold crossed (can cross multiple splits in one step)
                while accumulatedForSplit >= splitDistanceMeters, let splitStartTime {
                    let idx = splits.count + 1
                    let elapsed = loc.timestamp.timeIntervalSince(splitStartTime)
                    splits.append(RunSplit(index: idx, distanceMeters: splitDistanceMeters, durationSeconds: elapsed))
                    // reset for next split
                    accumulatedForSplit -= splitDistanceMeters
                    self.splitStartTime = loc.timestamp
                    splitStartIndex = route.count
                }
            } else {
                // first point
                splitStartTime = loc.timestamp
            }
            route.append(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // no-op; UI can react if needed
    }
}

