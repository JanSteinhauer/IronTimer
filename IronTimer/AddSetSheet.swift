//
//  AddSetSheet.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 13.09.25.
//

import SwiftUI

struct AddSetSheet: View {
    var onSave: (Int, Double) -> Void
    @State private var reps: Int = 8
    @State private var weight: Double = 20

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
