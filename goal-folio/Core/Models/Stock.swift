//
//  Ticker.swift
//  goal-folio
//
//  Created by Pratham S on 11/4/25.
//

import Foundation

struct Stock: Hashable, Codable {
    let symbol: String
    let name: String
    var type: String? = nil
    var region: String? = nil
    var currency: String? = nil
    
}

struct StockCandle: Codable, Hashable{
    let time: String      // ISO 8601 timestamp
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}
