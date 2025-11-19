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
        case .cash: return "Cash Assets"
        case .equities: return "Equities / Stocks"
        case .digitalAssets: return "Digital Assets"
        case .other: return "Other Positions"
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
        dateAdded: Date = Date()
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
