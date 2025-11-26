//
//  PositionsStore.swift
//  goal-folio
//
//  Created by Pratham S on 11/18/25.
// 
//

import SwiftUI
import Combine

class PositionsStore: ObservableObject {
    private static var positionsStoreKey = "savedPositions" // stores how much of each position does this person own
    private static var netWorthValuesKey = "netWorthValues" // stores daily and intraday net worth
    private static var positionsHistoryKey = "positionsHistory"

    @AppStorage(positionsStoreKey) private var positionsData: Data = Data()
    @AppStorage(netWorthValuesKey) private var netWorthValuesData: Data = Data()
    @AppStorage(positionsHistoryKey) private var positionsHistoryData: Data = Data()

    @Published var savedPositions: [Position] = []
    @Published var netWorthData: NetWorthData = NetWorthData()
    @Published var positionsHistory: [PositionsHistoryEntry] = []

    init(userDefaults: UserDefaults = .standard) {
        // Load persisted data
        if let loadedPositions = try? JSONDecoder().decode([Position].self, from: positionsData) {
            savedPositions = loadedPositions
        }

        // Load net worth data (if present)
        if let loadedNetWorth = try? JSONDecoder().decode(NetWorthData.self, from: netWorthValuesData) {
            netWorthData = loadedNetWorth
        }
        
        if let loadedPositionsHistory = try? JSONDecoder().decode([PositionsHistoryEntry].self, from: positionsHistoryData) {
            positionsHistory = loadedPositionsHistory
        }

        // Check if we need to rollover to a new day
        checkAndRolloverIntradayData()

        // Ensure today has proper intraday data
        initializeTodayIntradayData()

        // Update end-of-day snapshot and current intraday value
        updateNetWorthSnapshots()
    }

    // MARK: - Persistence

    private func savePositions() {
        positionsData = (try? JSONEncoder().encode(savedPositions)) ?? Data()
    }

    private func saveNetWorthData() {
        netWorthValuesData = (try? JSONEncoder().encode(netWorthData)) ?? Data()
    }
    
    private func savePositionsHistory() {
        positionsHistoryData = (try? JSONEncoder().encode(positionsHistory)) ?? Data()
    }
    
    private func addHistoryEntry(delta: Double, name: String) {
        let entry = PositionsHistoryEntry(timestamp: DateHelper.getDate(), delta: delta, name: name)
        positionsHistory.append(entry)
        savePositionsHistory()
    }

    private func checkAndRolloverIntradayData() {
        let today = DateHelper.getFormattedDate()
        
        // If it's a new day, clear intraday data
        if netWorthData.intradayDate != today {
            netWorthData.todayIntraday = []
            netWorthData.intradayDate = today
            saveNetWorthData()
        }
    }

    private func initializeTodayIntradayData() {
        guard netWorthData.todayIntraday.isEmpty else { return }
        
        // Get yesterday's closing value or use current value if no history
        let yesterday = DateHelper.getFormattedDate(for: Calendar.current.date(byAdding: .day, value: -1, to: DateHelper.getDate()) ?? DateHelper.getDate())
        let openingValue = netWorthData.dailySnapshots[yesterday] ?? totalMarketValue
        
        // Add opening snapshot at start of day
        let startOfDay = Calendar.current.startOfDay(for: DateHelper.getDate())
        netWorthData.todayIntraday.append(IntradaySnapshot(timestamp: startOfDay, netWorth: openingValue))
        netWorthData.intradayDate = DateHelper.getFormattedDate()
        saveNetWorthData()
    }

    private func updateNetWorthSnapshots() {
        let today = DateHelper.getFormattedDate()
        let currentValue = totalMarketValue
        
        // Update both daily and intraday snapshots
        netWorthData.dailySnapshots[today] = currentValue
        netWorthData.todayIntraday.append(IntradaySnapshot(timestamp: DateHelper.getDate(), netWorth: currentValue))
        
        saveNetWorthData()
    }

    // MARK: - CRUD Functions

    private func upsertPosition(category: PositionCategory, symbol: String? = nil, name: String, deltaQuantity: Double, unitPrice: Double, currency: String, notes: String? = nil) {
        // Find existing position
        let index: Int?
        switch category {
        case .cash:
            index = savedPositions.firstIndex { $0.category == .cash && $0.currency.uppercased() == currency.uppercased() }
        case .equities, .digitalAssets:
            let sym = symbol?.uppercased() ?? ""
            index = savedPositions.firstIndex { $0.category == category && $0.symbol?.uppercased() == sym && $0.currency.uppercased() == currency.uppercased() }
        case .other:
            let keyName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            index = savedPositions.firstIndex { $0.category == .other && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == keyName && $0.currency.uppercased() == currency.uppercased() }
        }
        
        // Calculate the monetary delta for history
        let monetaryDelta = deltaQuantity * unitPrice
        
        // Update existing or add new position
        if let idx = index {
            var existing = savedPositions[idx]
            existing.quantity += deltaQuantity
            existing.unitPrice = unitPrice != 0 ? unitPrice : existing.unitPrice
            
            // Remove if quantity reaches zero or becomes negative
            if existing.quantity <= 0 {
                savedPositions.remove(at: idx)
                // Record removal in history as negative delta
                let removalDelta = -(existing.quantity - deltaQuantity) * existing.unitPrice
                addHistoryEntry(delta: removalDelta, name: "Removed: \(name)")
            } else {
                savedPositions[idx] = existing
                // Record update in history
                addHistoryEntry(delta: monetaryDelta, name: name)
            }
        } else if deltaQuantity > 0 {
            // Only add new position if delta is positive
            // because we can't add a negative of something that isn't in the system
            savedPositions.append(Position(
                category: category,
                symbol: symbol?.uppercased(),
                name: name,
                quantity: deltaQuantity,
                unitPrice: unitPrice,
                currency: currency,
                notes: notes
            ))
            // Record addition in history
            addHistoryEntry(delta: monetaryDelta, name: "Added: \(name)")
        }
        
        savePositions()
        updateNetWorthSnapshots()
    }

    func addCash(amount: Double, currency: String = "USD", name: String = "Cash") {
        upsertPosition(category: .cash, name: name, deltaQuantity: amount, unitPrice: 1.0, currency: currency)
    }

    func addEquity(symbol: String, name: String, shares: Double, unitPrice: Double, currency: String = "USD", notes: String? = nil) {
        upsertPosition(category: .equities, symbol: symbol, name: name, deltaQuantity: shares, unitPrice: unitPrice, currency: currency, notes: notes)
    }

    func addDigitalAsset(symbol: String, name: String, units: Double, unitPrice: Double, currency: String = "USD", notes: String? = nil) {
        upsertPosition(category: .digitalAssets, symbol: symbol, name: name, deltaQuantity: units, unitPrice: unitPrice, currency: currency, notes: notes)
    }

    func addOther(name: String, amount: Double, unitPrice: Double = 1.0, currency: String = "USD", notes: String? = nil) {
        upsertPosition(category: .other, name: name, deltaQuantity: amount, unitPrice: unitPrice, currency: currency, notes: notes)
    }

    func update(_ position: Position) {
        // directly update a position:
        guard let idx = savedPositions.firstIndex(where: { $0.id == position.id }) else { return }
        let oldPosition = savedPositions[idx]
        
        // Calculate the change in market value
        let oldValue = oldPosition.marketValue
        let newValue = position.marketValue
        let delta = newValue - oldValue
        
        savedPositions[idx] = position
        
        // Record update in history if value changed
        if delta != 0 {
            addHistoryEntry(delta: delta, name: "Updated: \(position.name)")
        }
        
        savePositions()
        updateNetWorthSnapshots()
    }

    func remove(id: UUID) {
        // Find the position before removing to record in history
        if let position = savedPositions.first(where: { $0.id == id }) {
            let delta = -position.marketValue
            addHistoryEntry(delta: delta, name: "Removed: \(position.name)")
        }
        
        savedPositions.removeAll { $0.id == id }
        savePositions()
        updateNetWorthSnapshots()
    }

    func removeAll(in category: PositionCategory) {
        // Record removal of all positions in this category
        let positionsToRemove = savedPositions.filter { $0.category == category }
        let totalValue = positionsToRemove.reduce(0) { $0 + $1.marketValue }
        
        if totalValue > 0 {
            addHistoryEntry(delta: -totalValue, name: "Removed all: \(category.displayName)")
        }
        
        savedPositions.removeAll { $0.category == category }
        savePositions()
        updateNetWorthSnapshots()
    }

    // MARK: - Helpers / Queries

    func positions(in category: PositionCategory) -> [Position] {
        savedPositions.filter { $0.category == category }
    }

    var cashPositions: [Position] { positions(in: .cash) }
    var equityPositions: [Position] { positions(in: .equities) }
    var digitalAssetPositions: [Position] { positions(in: .digitalAssets) }
    var otherPositions: [Position] { positions(in: .other) }

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
}

