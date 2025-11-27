//
//  AddPositionView.swift
//  goal-folio
//
//  Created by Pratham S on 11/20/25.
//

import SwiftUI

struct AddPositionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var positionsStore: PositionsStore

    // MARK: - Form state
    @State private var category: PositionCategory = .equities

    // Shared fields
    @State private var name: String = ""
    @State private var currency: String = "USD"
    @State private var notes: String = ""

    // Asset fields
    @State private var symbol: String = ""
    @State private var quantityText: String = ""
    @State private var unitPriceText: String = ""

    // Cash fields
    @State private var cashAmountText: String = ""

    // Deposit (+) vs Withdrawal (-)
    private enum TransactionType: String, CaseIterable, Identifiable {
        case deposit = "Deposit"
        case withdrawal = "Withdrawal"
        var id: String { rawValue }
        var sign: Double { self == .deposit ? 1 : -1 }
    }
    @State private var txnType: TransactionType = .deposit

    // MARK: - Validation helpers

    private func parseDouble(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
    }

    private var quantity: Double? { parseDouble(quantityText) }
    private var unitPrice: Double? { parseDouble(unitPriceText) }
    private var cashAmount: Double? { parseDouble(cashAmountText) }

    private var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isSymbolValid: Bool {
        switch category {
        case .equities, .digitalAssets:
            return !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }
    private var isCurrencyValid: Bool {
        let code = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return code.count >= 3 && code.count <= 6
    }
    private var isNumbersValid: Bool {
        switch category {
        case .cash:
            if let a = cashAmount { return a > 0 }
            return false
        case .equities, .digitalAssets, .other:
            guard let q = quantity, let p = unitPrice else { return false }
            return q > 0 && p > 0
        }
    }

    private var canSave: Bool {
        isNameValid && isSymbolValid && isCurrencyValid && isNumbersValid
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Place the segmented Category picker OUTSIDE the Form to avoid the extra outer border look.
                categoryPicker

                Form {
                    // Transaction type
                    Section {
                        Picker("Type", selection: $txnType) {
                            ForEach(TransactionType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Contextual fields
                    switch category {
                    case .cash:
                        cashSection
                    case .equities, .digitalAssets:
                        assetSection
                    case .other:
                        otherSection
                    }

                    // Currency
                    Section(header: Text("Currency")) {
                        TextField("Currency code (e.g., USD)", text: $currency)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: currency) { currency = currency.uppercased() }

                        if !isCurrencyValid && !currency.isEmpty {
                            Text("Enter a 3–6 character currency or token code.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    // Notes
                    if category != .cash {
                        Section(header: Text("Notes")) {
                            TextField("Optional notes", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Add Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if category == .cash, name.isEmpty { name = "USD Cash" }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Subviews

    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            ForEach(PositionCategory.allCases) { c in
                Text(c.displayName).tag(c)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var cashSection: some View {
        Section(header: Text("Cash")) {
            TextField("Name", text: $name)
                .textContentType(.name)
                .autocorrectionDisabled()

            TextField("Amount", text: $cashAmountText)
                .keyboardType(.decimalPad)

            if !isNumbersValid && !cashAmountText.isEmpty {
                Text("Enter a valid amount greater than 0.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var assetSection: some View {
        Section(header: Text("Asset")) {
            TextField("Symbol", text: $symbol)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            TextField("Name", text: $name)
                .textContentType(.name)
                .autocorrectionDisabled()

            HStack {
                TextField("Quantity", text: $quantityText)
                    .keyboardType(.decimalPad)
                Spacer()
                TextField("Unit Price", text: $unitPriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            if !isNumbersValid && (!quantityText.isEmpty || !unitPriceText.isEmpty) {
                Text("Enter valid positive numbers for Quantity and Unit Price.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var otherSection: some View {
        Section(header: Text("Position")) {
            TextField("Name", text: $name)
                .textContentType(.name)
                .autocorrectionDisabled()

            HStack {
                TextField("Quantity", text: $quantityText)
                    .keyboardType(.decimalPad)
                Spacer()
                TextField("Unit Price", text: $unitPriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            if !isNumbersValid && (!quantityText.isEmpty || !unitPriceText.isEmpty) {
                Text("Enter valid positive numbers for Quantity and Unit Price.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let code = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        switch category {
        case .cash:
            let amount = (cashAmount ?? 0) * txnType.sign
            positionsStore.addCash(amount: amount, currency: code, name: name.trimmed())

        case .equities:
            guard let q = quantity, let p = unitPrice else { return }
            positionsStore.addEquity(symbol: symbol.trimmed().uppercased(),
                                     name: name.trimmed(),
                                     shares: q * txnType.sign,
                                     unitPrice: p,
                                     currency: code,
                                     notes: notes.trimmedOrNil())

        case .digitalAssets:
            guard let q = quantity, let p = unitPrice else { return }
            positionsStore.addDigitalAsset(symbol: symbol.trimmed().uppercased(),
                                           name: name.trimmed(),
                                           units: q * txnType.sign,
                                           unitPrice: p,
                                           currency: code,
                                           notes: notes.trimmedOrNil())

        case .other:
            guard let q = quantity, let p = unitPrice else { return }
            positionsStore.addOther(name: name.trimmed(),
                                    amount: q * txnType.sign,
                                    unitPrice: p,
                                    currency: code,
                                    notes: notes.trimmedOrNil())
        }

        dismiss()
    }
}

// MARK: - Small helpers

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func trimmedOrNil() -> String? {
        let t = trimmed()
        return t.isEmpty ? nil : t
    }
}

#Preview {
    NavigationStack {
        AddPositionView()
            .environmentObject(PositionsStore())
    }
}
