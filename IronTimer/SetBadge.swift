//
//  SetBadge.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI

struct SetBadge: View {
    let reps: Int
    let weight: Double
    var body: some View {
        Text("\(reps)x@\(weight.clean)kg")
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

