//
//  TickerStore.swift.swift
//  goal-folio
//
//  Created by Pratham S on 11/8/25.
//

import SwiftUI
import Combine

class StockStore: ObservableObject {
    private static var stocksStoreKey = "savedStocks"
    
    @AppStorage(stocksStoreKey) private var stockData: Data = Data()
    @Published var savedStocks: [Stock] = []
    
    init(userDefaults: UserDefaults = .standard) {
        // if this tickerstore has never been initialized
        // initialize it with some defualt stock tickers
        if userDefaults.object(forKey: Self.stocksStoreKey) == nil {
            savedStocks = [
                Stock(symbol: "AAPL", name: "Apple Inc."),
                Stock(symbol: "GOOGL", name: "Alphabet Inc."),
                Stock(symbol: "AMZN", name: "Amazon.com, Inc."),
                Stock(symbol: "VOO", name: "Vanguard S&P 500 ETF")
            ]
            save()
        }
        
        savedStocks = (try? JSONDecoder().decode([Stock].self, from: stockData)) ?? []
                
    }
    
    private func save() {
        stockData = (try? JSONEncoder().encode(savedStocks)) ?? Data()
    }
    
    func saveStock(symbol: String, name: String) {
        savedStocks.append(Stock(symbol: symbol, name: name))
        save()
    }
    
    func removeStock(symbol: String) {
        savedStocks.removeAll {$0.symbol.lowercased() == symbol.lowercased()}
    }
    
    func isStockSaved(symbol: String) -> Bool {
        for stock in savedStocks {
            if stock.symbol == symbol {
                return true
            }
        }
        
        return false
    }
}
