//
//  Ticker.swift
//  goal-folio
//
//  Created by Pratham S on 11/4/25.
//

import Foundation

struct Stock: Identifiable, Hashable, Codable {
    let id = UUID()
    let symbol: String
    let name: String
    var type: String? = nil
    var region: String? = nil
    var currency: String? = nil
    
}

struct StockCandle: Identifiable, Codable {
    let id = UUID()
    let time: String      // ISO 8601 timestamp
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}
