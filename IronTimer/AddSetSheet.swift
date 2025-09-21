//
//  AddSetSheet.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI

struct AddSetSheet: View {
    var onSave: (Int, Double) -> Void
    var initialReps: Int?
    var initialWeight: Double?

    @State private var reps: Int
    @State private var weight: Double

    init(initialReps: Int? = nil, initialWeight: Double? = nil, onSave: @escaping (Int, Double) -> Void) {
        self.onSave = onSave
        self.initialReps = initialReps
        self.initialWeight = initialWeight
        _reps = State(initialValue: initialReps ?? 8)
        _weight = State(initialValue: initialWeight ?? 20)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $reps, in: 1...100) {
                    HStack { Text("Reps"); Spacer(); Text("\(reps)") }
                }
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("kg", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
            }
            .navigationTitle("Add Set")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(reps, max(0, weight)); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}


