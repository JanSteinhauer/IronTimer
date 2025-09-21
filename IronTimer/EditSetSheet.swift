//
//  EditSetSheet.swift
//  IronTimer
//
//  Created by Steinhauer, Jan on 21.09.25.
//

import SwiftUI
import SwiftData

struct EditSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var set: SetRecord

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $set.reps, in: 1...100) {
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(set.reps)")
                    }
                }
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("kg", value: $set.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .navigationTitle("Edit Set")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

