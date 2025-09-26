//
//  RunModels.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 26.09.25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Run {
    var dateStart: Date
    var dateEnd: Date?
    var unitIsMetric: Bool           // true = km, false = miles
    var type: RunType
    var feeling: RunFeeling
    var notes: String

    // Summary
    var totalDistanceMeters: Double  // accumulated
    var totalDurationSeconds: Double // accumulated

    // Route + splits
    var route: [RoutePoint]
    var splits: [RunSplit]

    init(dateStart: Date = .now,
         unitIsMetric: Bool = true,
         type: RunType = .easy,
         feeling: RunFeeling = .okay,
         notes: String = "",
         totalDistanceMeters: Double = 0,
         totalDurationSeconds: Double = 0,
         route: [RoutePoint] = [],
         splits: [RunSplit] = [])
    {
        self.dateStart = dateStart
        self.unitIsMetric = unitIsMetric
        self.type = type
        self.feeling = feeling
        self.notes = notes
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
        self.route = route
        self.splits = splits
    }

    var avgPaceSecondsPerKm: Double? {
        guard totalDistanceMeters > 0, totalDurationSeconds > 0 else { return nil }
        return (totalDurationSeconds / (totalDistanceMeters / 1000.0))
    }

    var avgPaceSecondsPerMile: Double? {
        guard totalDistanceMeters > 0, totalDurationSeconds > 0 else { return nil }
        return (totalDurationSeconds / (totalDistanceMeters / 1609.344))
    }
}

@Model
final class RoutePoint {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var hAcc: Double?

    init(timestamp: Date, latitude: Double, longitude: Double, altitude: Double? = nil, hAcc: Double? = nil) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.hAcc = hAcc
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Model
final class RunSplit {
    // index starts at 1
    var index: Int
    var distanceMeters: Double
    var durationSeconds: Double

    init(index: Int, distanceMeters: Double, durationSeconds: Double) {
        self.index = index
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
    }

    var paceSecPerKm: Double? {
        guard distanceMeters > 0 else { return nil }
        return durationSeconds / (distanceMeters / 1000.0)
    }

    var paceSecPerMile: Double? {
        guard distanceMeters > 0 else { return nil }
        return durationSeconds / (distanceMeters / 1609.344)
    }
}

enum RunType: String, Codable, CaseIterable {
    case easy, long, interval, tempo, race
}

enum RunFeeling: String, Codable, CaseIterable {
    case great, okay, tired, injured
}
