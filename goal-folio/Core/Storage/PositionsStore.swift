//
//  PositionsStore.swift
//  goal-folio
//
//  Created by Pratham S on 11/18/25.
//

import SwiftUI
import Combine

class PositionsStore: ObservableObject {
    private static var positionsStoreKey = "savedPositions"
    private static var dailyMarketValuesKey = "dailyMarketValues" // persistence key for the time series

    @AppStorage(positionsStoreKey) private var positionsData: Data = Data()
    @AppStorage(dailyMarketValuesKey) private var dailyMarketValuesData: Data = Data()

    @Published var savedPositions: [Position] = []
    // Dictionary keyed by date string "yyyy-MM-dd" (no time), value is total portfolio market value for that day.
    @Published var dailyMarketValueByDate: [String: Double] = [:]

    init(userDefaults: UserDefaults = .standard) {
        // Seed defaults on first run
        if userDefaults.object(forKey: Self.positionsStoreKey) == nil {
            savedPositions = Self.defaultSeedPositions()
            savePositions()
        }

        // Load persisted data
        if let loaded = try? JSONDecoder().decode([Position].self, from: positionsData) {
            savedPositions = loaded
        }

        // Load time series (if present)
        if let loadedDaily = try? JSONDecoder().decode([String: Double].self, from: dailyMarketValuesData) {
            dailyMarketValueByDate = loadedDaily
        }

        // If empty, mock a simple historical series
        seedDailyMarketValuesIfNeeded()

        // Ensure today's market value exists/updated
        updateTodayMarketValue()
    }

    // MARK: - Persistence

    private func savePositions() {
        positionsData = (try? JSONEncoder().encode(savedPositions)) ?? Data()
    }

    private func saveDailyMarketValues() {
        dailyMarketValuesData = (try? JSONEncoder().encode(dailyMarketValueByDate)) ?? Data()
    }

    private var todayKey: String {
        DateHelper.getFormattedDate()
    }

    private func updateTodayMarketValue() {
        dailyMarketValueByDate[todayKey] = totalMarketValue
        saveDailyMarketValues()
    }

    // MARK: - Mock seeding

    // Generates a last-30-days daily series if none exists, based on current totalMarketValue with small random drift.
    private func seedDailyMarketValuesIfNeeded(days: Int = 30) {
        guard dailyMarketValueByDate.isEmpty else { return }

        let calendar = Calendar(identifier: .gregorian)
        let baseToday = Date()
        let baseValue = max(totalMarketValue, 1.0) // avoid zero baseline

        var series: [String: Double] = [:]
        var running = baseValue

        // Generate from oldest to newest
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: baseToday) else { continue }

            // Simulate day-over-day change within +/- 1.5%
            let pctChange = Double.random(in: -0.015...0.015)
            if offset != days - 1 {
                running = max(0, running * (1.0 + pctChange))
            }

            let key = DateHelper.getFormattedDate(for: date)
            series[key] = running
        }

        dailyMarketValueByDate = series
        saveDailyMarketValues()
    }

    // MARK: - CRUD Functions

    // Internal add used by seed
    private func add(_ position: Position) {
        savedPositions.append(position)
        savePositions()
        updateTodayMarketValue()
    }

    // Upsert helpers: find existing active position by matching key
    private func indexForCash(currency: String) -> Int? {
        savedPositions.firstIndex {
            $0.category == .cash && $0.currency.uppercased() == currency.uppercased()
        }
    }

    private func indexForEquity(symbol: String, currency: String) -> Int? {
        let sym = symbol.uppercased()
        return savedPositions.firstIndex {
            $0.category == .equities &&
            ($0.symbol?.uppercased() == sym) &&
            $0.currency.uppercased() == currency.uppercased()
        }
    }

    private func indexForDigital(symbol: String, currency: String) -> Int? {
        let sym = symbol.uppercased()
        return savedPositions.firstIndex {
            $0.category == .digitalAssets &&
            ($0.symbol?.uppercased() == sym) &&
            $0.currency.uppercased() == currency.uppercased()
        }
    }

    private func indexForOther(name: String, currency: String) -> Int? {
        let keyName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return savedPositions.firstIndex {
            $0.category == .other &&
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == keyName &&
            $0.currency.uppercased() == currency.uppercased()
        }
    }

    private func upsert(at index: Int?, with newPosition: Position, deltaQuantity: Double) {
        if let idx = index {
            var existing = savedPositions[idx]
            existing.quantity += deltaQuantity
            // Keep unitPrice as last provided price for now (could be refined to VWAP/average cost if desired)
            existing.unitPrice = newPosition.unitPrice != 0 ? newPosition.unitPrice : existing.unitPrice
            if existing.quantity == 0 {
                savedPositions.remove(at: idx)
            } else if existing.quantity < 0 {
                // Prevent negative holdings; clamp to zero and remove
                savedPositions.remove(at: idx)
            } else {
                savedPositions[idx] = existing
            }
        } else {
            // No existing position: only add if delta is positive
            guard deltaQuantity > 0 else {
                // Ignore pure withdrawals when nothing exists
                savePositions()
                updateTodayMarketValue()
                return
            }
            var toAdd = newPosition
            toAdd.quantity = deltaQuantity
            savedPositions.append(toAdd)
        }
        savePositions()
        updateTodayMarketValue()
    }

    func addCash(amount: Double, currency: String = "USD", name: String = "Cash") {
        // amount can be positive (deposit) or negative (withdrawal)
        let idx = indexForCash(currency: currency)
        let p = Position(
            category: .cash,
            symbol: nil,
            name: name,
            quantity: 0, // delta applied in upsert
            unitPrice: 1.0,
            currency: currency
        )
        upsert(at: idx, with: p, deltaQuantity: amount)
    }

    func addEquity(symbol: String, name: String, shares: Double, unitPrice: Double, currency: String = "USD", notes: String? = nil) {
        let idx = indexForEquity(symbol: symbol, currency: currency)
        let p = Position(
            category: .equities,
            symbol: symbol.uppercased(),
            name: name,
            quantity: 0,
            unitPrice: unitPrice,
            currency: currency,
            notes: notes
        )
        upsert(at: idx, with: p, deltaQuantity: shares)
    }

    func addDigitalAsset(symbol: String, name: String, units: Double, unitPrice: Double, currency: String = "USD", notes: String? = nil) {
        let idx = indexForDigital(symbol: symbol, currency: currency)
        let p = Position(
            category: .digitalAssets,
            symbol: symbol.uppercased(),
            name: name,
            quantity: 0,
            unitPrice: unitPrice,
            currency: currency,
            notes: notes
        )
        upsert(at: idx, with: p, deltaQuantity: units)
    }

    func addOther(name: String, amount: Double, unitPrice: Double = 1.0, currency: String = "USD", notes: String? = nil) {
        let idx = indexForOther(name: name, currency: currency)
        let p = Position(
            category: .other,
            symbol: nil,
            name: name,
            quantity: 0,
            unitPrice: unitPrice,
            currency: currency,
            notes: notes
        )
        upsert(at: idx, with: p, deltaQuantity: amount)
    }

    func update(_ position: Position) {
        guard let idx = savedPositions.firstIndex(where: { $0.id == position.id }) else { return }
        savedPositions[idx] = position
        savePositions()
        updateTodayMarketValue()
    }

    func remove(id: UUID) {
        savedPositions.removeAll { $0.id == id }
        savePositions()
        updateTodayMarketValue()
    }

    func removeAll(in category: PositionCategory) {
        savedPositions.removeAll { $0.category == category }
        savePositions()
        updateTodayMarketValue()
    }

    // MARK: - Helpers / Queries

    var cashPositions: [Position] { savedPositions.filter { $0.category == .cash } }
    var equityPositions: [Position] { savedPositions.filter { $0.category == .equities } }
    var digitalAssetPositions: [Position] { savedPositions.filter { $0.category == .digitalAssets } }
    var otherPositions: [Position] { savedPositions.filter { $0.category == .other } }

    func positions(in category: PositionCategory) -> [Position] {
        savedPositions.filter { $0.category == category }
    }

    var totalMarketValue: Double {
        savedPositions.reduce(0) { $0 + $1.marketValue }
    }

    // A merged list for display: all cash combined into a single "Cash" row per currency (default: one row if only USD).
    var displayPositions: [Position] {
        // 1) Merge cash by currency into a single row per currency, named "Cash"
        let cashByCurrency = Dictionary(grouping: cashPositions, by: { $0.currency.uppercased() })
            .map { (currency, items) -> Position in
                let totalQty = items.reduce(0.0) { $0 + $1.quantity }
                // If total becomes zero, omit the row
                return Position(
                    category: .cash,
                    symbol: nil,
                    name: "Cash",
                    quantity: totalQty,
                    unitPrice: 1.0,
                    currency: currency
                )
            }
            .filter { $0.quantity != 0 }

        // 2) Non-cash positions as-is (but filter out zeroed positions just in case)
        let nonCash = savedPositions.filter { $0.category != .cash && $0.quantity != 0 }

        // 3) Return combined list
        return nonCash + cashByCurrency
    }

    // MARK: - Seed

    private static func defaultSeedPositions() -> [Position] {
        [
            // Cash
            Position(category: .cash, name: "USD Cash", quantity: 1000.0, unitPrice: 1.0, currency: "USD"),
            // Equities
            Position(category: .equities, symbol: "AAPL", name: "Apple Inc.", quantity: 5.0, unitPrice: 180.0, currency: "USD"),
            // Digital Assets
            Position(category: .digitalAssets, symbol: "BTC", name: "Bitcoin", quantity: 0.01, unitPrice: 65000.0, currency: "USD"),
            // Other
            Position(category: .other, name: "Savings Bond", quantity: 1.0, unitPrice: 500.0, currency: "USD")
        ]
    }
}

