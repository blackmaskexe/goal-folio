//
//  Positions.swift
//  goal-folio
//
//  Created by Pratham S on 11/18/25.
//
import SwiftUI
import Combine

enum PositionCategory: String, Codable, CaseIterable, Identifiable {
    case cash
    case equities
    case digitalAssets
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .equities: return "Equities"
        case .digitalAssets: return "Digital"
        case .other: return "Other"
        }
    }
}

/// A unified position model that can represent Cash, Equities, Digital Assets, or Other.
/// - For cash positions: use quantity as the cash amount, unitPrice = 1.0 (or 0), and symbol/name like "USD Cash".
/// - For equities/digital assets: use symbol, name, quantity (units), and unitPrice (cost per unit or current price if you prefer).
struct Position: Identifiable, Hashable, Codable {
    let id: UUID
    var category: PositionCategory

    // Common identification
    var symbol: String?      // e.g., "AAPL" or "BTC"
    var name: String         // e.g., "Apple Inc." or "USD Cash"

    // Holdings
    var quantity: Double     // For cash: total amount; for assets: number of units
    var unitPrice: Double    // For cash you can use 1.0 or 0; for assets: price per unit (could be cost basis or last price)
    var currency: String     // ISO code, e.g., "USD"

    // Metadata
    var notes: String?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        category: PositionCategory,
        symbol: String? = nil,
        name: String,
        quantity: Double,
        unitPrice: Double,
        currency: String = "USD",
        notes: String? = nil,
        dateAdded: Date = DateHelper.getDate()
    ) {
        self.id = id
        self.category = category
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.currency = currency
        self.notes = notes
        self.dateAdded = dateAdded
    }

    // Convenience computed values
    var marketValue: Double { quantity * unitPrice }
}

struct IntradaySnapshot: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let netWorth: Double
    
    init(id: UUID = UUID(), timestamp: Date = DateHelper.getDate(), netWorth: Double) {
        self.id = id
        self.timestamp = timestamp
        self.netWorth = netWorth
    }
}

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

struct PositionsHistoryEntry: Codable {
    let id: UUID
    let timestamp: Date
    let delta: Double
    let name: String
    
    init(id: UUID = UUID(), timestamp: Date = DateHelper.getDate(), delta: Double, name: String) {
        self.id = id
        self.timestamp = timestamp
        self.delta = delta
        self.name = name
    }
}
