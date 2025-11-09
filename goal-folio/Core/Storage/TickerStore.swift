//
//  TickerStore.swift.swift
//  goal-folio
//
//  Created by Pratham S on 11/8/25.
//

import SwiftUI
import Combine

class TickerStore: ObservableObject {
    private static var tickerStoreKey = "savedTickers"
    
    @AppStorage(tickerStoreKey) private var tickerData: Data = Data()
    @Published var savedTickers: [Ticker] = []
    
    init(userDefaults: UserDefaults = .standard) {
        // if this tickerstore has never been initialized
        // initialize it with some defualt stock tickers
        if userDefaults.object(forKey: Self.tickerStoreKey) == nil {
            savedTickers = [
                Ticker(symbol: "AAPL", name: "Apple Inc."),
                Ticker(symbol: "GOOGL", name: "Alphabet Inc."),
                Ticker(symbol: "AMZN", name: "Amazon.com, Inc."),
                Ticker(symbol: "VOO", name: "Vanguard S&P 500 ETF")
            ]
            save()
        }
        
        savedTickers = (try? JSONDecoder().decode([Ticker].self, from: tickerData)) ?? []
                
    }
    
    private func save() {
        tickerData = (try? JSONEncoder().encode(savedTickers)) ?? Data()
    }
    
    func saveTicker(symbol: String, name: String) {
        savedTickers.append(Ticker(symbol: symbol, name: name))
        save()
    }
    
    func removeTicker(symbol: String) {
        savedTickers.removeAll {$0.symbol.lowercased() == symbol.lowercased()}
    }
    
    func isTickerSaved(symbol: String) -> Bool {
        for ticker in savedTickers {
            if ticker.symbol == symbol {
                return true
            }
        }
        
        return false
    }
}
