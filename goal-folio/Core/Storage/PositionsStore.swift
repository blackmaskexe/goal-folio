//
//  PositionsStore.swift
//  goal-folio
//
//  Created by Pratham S on 11/18/25.
// 
//

import SwiftUI
import Combine

// MARK: - Intraday Snapshot Model

struct IntradaySnapshot: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let netWorth: Double
    
    init(id: UUID = UUID(), timestamp: Date = Date(), netWorth: Double) {
        self.id = id
        self.timestamp = timestamp
        self.netWorth = netWorth
    }
}

// MARK: - Net Worth Data Model

struct NetWorthData: Codable {
    var dailySnapshots: [String: Double]        // "yyyy-MM-dd" -> end-of-day net worth
    var todayIntraday: [IntradaySnapshot]       // Timestamped entries for current day only
    var intradayDate: String?                   // Track which day the intraday data belongs to
    
    init(dailySnapshots: [String: Double] = [:], todayIntraday: [IntradaySnapshot] = [], intradayDate: String? = nil) {
        self.dailySnapshots = dailySnapshots
        self.todayIntraday = todayIntraday
        self.intradayDate = intradayDate
    }
}

class PositionsStore: ObservableObject {
    private static var positionsStoreKey = "savedPositions" // stores how much of each position does this person own
    private static var netWorthValuesKey = "netWorthValues" // stores daily and intraday net worth

    @AppStorage(positionsStoreKey) private var positionsData: Data = Data()
    
    @AppStorage(netWorthValuesKey) private var netWorthValuesData: Data = Data()

    @Published var savedPositions: [Position] = []
    @Published var netWorthData: NetWorthData = NetWorthData()

    init(userDefaults: UserDefaults = .standard) {
        // Load persisted data
        if let loaded = try? JSONDecoder().decode([Position].self, from: positionsData) {
            savedPositions = loaded
        }

        // Load net worth data (if present)
        if let loadedNetWorth = try? JSONDecoder().decode(NetWorthData.self, from: netWorthValuesData) {
            netWorthData = loadedNetWorth
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

    private var todayKey: String {
        DateHelper.getFormattedDate()
    }

    private func checkAndRolloverIntradayData() {
        let today = todayKey
        
        // If intraday data is from a different day, clear it and start fresh
        if let existingDate = netWorthData.intradayDate, existingDate != today {
            netWorthData.todayIntraday = []
            netWorthData.intradayDate = today
            saveNetWorthData()
        } else if netWorthData.intradayDate == nil {
            // First time setup
            netWorthData.intradayDate = today
        }
    }

    private func initializeTodayIntradayData() {
        // If we have no intraday data for today, initialize with opening value
        guard netWorthData.todayIntraday.isEmpty else { return }
        
        let today = todayKey
        let yesterday = getYesterdayKey()
        
        // Get opening value: yesterday's closing or current market value
        let openingValue = netWorthData.dailySnapshots[yesterday] ?? totalMarketValue
        
        // Create opening snapshot at start of day (00:00:00)
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date())
        
        let openingSnapshot = IntradaySnapshot(timestamp: startOfDay, netWorth: openingValue)
        netWorthData.todayIntraday.append(openingSnapshot)
        netWorthData.intradayDate = today
        saveNetWorthData()
    }

    private func updateNetWorthSnapshots() {
        let today = todayKey
        let currentValue = totalMarketValue
        
        // Update daily snapshot for today
        netWorthData.dailySnapshots[today] = currentValue
        
        // Add or update current intraday snapshot
        addIntradaySnapshot(netWorth: currentValue)
        
        saveNetWorthData()
    }

    private func addIntradaySnapshot(netWorth: Double) {
        // Always add a new snapshot on position changes
        let snapshot = IntradaySnapshot(timestamp: Date(), netWorth: netWorth)
        netWorthData.todayIntraday.append(snapshot)
    }

    private func getYesterdayKey() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return DateHelper.getFormattedDate(for: yesterday)
    }

    // MARK: - CRUD Functions

    // Internal add used by seed
    private func add(_ position: Position) {
        savedPositions.append(position)
        savePositions()
        updateNetWorthSnapshots()
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
        updateNetWorthSnapshots()
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
        updateNetWorthSnapshots()
    }

    func remove(id: UUID) {
        savedPositions.removeAll { $0.id == id }
        savePositions()
        updateNetWorthSnapshots()
    }

    func removeAll(in category: PositionCategory) {
        savedPositions.removeAll { $0.category == category }
        savePositions()
        updateNetWorthSnapshots()
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
}

