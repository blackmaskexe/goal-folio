//
//  FinnhubService.swift
//  goal-folio
//
//  Created by Pratham S on 11/7/25.
//

import Alamofire
import Foundation

struct StockCandle {
    let time: Date
    let close: Double
}

class AlphaVantageService {
    private let baseURL = "https://www.alphavantage.co/query"
    private let apiKey = "H57SGIIXB3QA5MXA"
    
    func fetchIntradayPrices(symbol: String) async throws -> [StockCandle] {
        let apiKey = "H57SGIIXB3QA5MXA"
        let url = "https://www.alphavantage.co/query"
        
        let params: Parameters = [
            "function": "TIME_SERIES_INTRADAY",
            "symbol": symbol,
            "interval": "60min",
            "apikey": apiKey,
            "outputsize": "compact",
            "extended_hours": "false"
        ]

        let dataResponse = try await AF.request(url, parameters: params).serializingData().value

        guard let json = try JSONSerialization.jsonObject(with: dataResponse) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON", code: 0)
        }

        guard let timeSeriesKey = json.keys.first(where: { $0.contains("Time Series") }),
              let timeSeries = json[timeSeriesKey] as? [String: [String: String]] else {
            throw NSError(domain: "Time Series not found", code: 0)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "US/Eastern")

        let prices: [StockCandle] = timeSeries.compactMap { timestamp, dataDict in
            guard let date = formatter.date(from: timestamp),
                  let closeStr = dataDict["4. close"],
                  let close = Double(closeStr) else { return nil }
            return StockCandle(time: date, close: close)
        }

        return prices.sorted { $0.time < $1.time }
    }
    
    func getRecentOpenDayCandles(symbol: String) async throws -> [StockCandle] {
        
        // The array to return at the end:
        var lastOpenDayCandles: [StockCandle] = []

        // 1. fetch intraday prices
        let stockPrices: [StockCandle] = try await self.fetchIntradayPrices(symbol: symbol)
        
        // 2. find what the last entry in the fetched array is, that's the last day the stock market was last open
        if (stockPrices.count > 0) {
            let lastOpenDate: Date = stockPrices[stockPrices.count - 1].time
            
            // 3. fetch all the entires under that date
            for candle in stockPrices {
                if Calendar.current.isDate(lastOpenDate, inSameDayAs: candle.time) {
                    lastOpenDayCandles.append(candle)
                }
            }
            
        }
        
        return lastOpenDayCandles
    }
    
    
}

