//
//  AddFloatingButton.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI

struct AddFloatingButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.18)).frame(width: 56, height: 56)
                Image(systemName: "plus").font(.system(size: 28, weight: .bold)).foregroundColor(.ironOrange)
            }
            .padding(8)
            .shadow(radius: 6)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Add Exercise")
    }
}

// MARK: - Utils
func simpleHaptic() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    #endif
}

extension Double {
    var clean: String {
        let v = self
        return v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}
