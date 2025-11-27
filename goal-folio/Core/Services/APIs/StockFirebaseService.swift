//
//  StockFirebaseService.swift
//  goal-folio
//
//  Created by Pratham S on 11/14/25.
//


import Foundation
import FirebaseFunctions

/// Service for fetching stock data through Firebase Cloud Functions
/// Replaces direct Alpha Vantage API calls with cached, rate-limited backend calls
class StockFirebaseService {
    private let functions = Functions.functions()
    static let shared = StockFirebaseService()
    
    // Initialization:
    private init() {
        // Optional: Configure for specific region if needed
        // functions = Functions.functions(region: "us-central1")
    }
    
    // Models:
    struct SearchResponse: Codable {
        let success: Bool
        let query: String
        let count: Int
        let fromCache: Bool
        let results: [Stock]
        let apiError: String?
    }
    
    struct StockDetailsResponse: Codable {
        let success: Bool
        let result: StockDetails?
        let error: String?
    }
    
    struct StockDetails: Codable {
        let symbol: String
        let name: String
        let type: String
        let region: String
        let currency: String
        let lastUpdated: String
    }
    
    struct IntradayPricesResponse: Codable {
        let symbol: String
        let interval: String
        let candles: [StockCandle]
    }
    
    struct RecentOpenDayResponse: Codable {
        let symbol: String
        let interval: String
        let tradingDay: String?
        let candles: [StockCandle]
    }
    
    enum FirebaseServiceError: LocalizedError {
        case invalidResponse
        case serverError(String)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let message):
                return "Server error: \(message)"
            case .noData:
                return "No data received"
            }
        }
    }
    
    enum PriceServiceError: LocalizedError {
        case invalidResponse
        case decodingFailed
        case emptySymbol
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .decodingFailed:
                return "Failed to decode response data"
            case .emptySymbol:
                return "Stock symbol cannot be empty"
            }
        }
    }
    
    // SEARCH FUNCTIONS:
    
    /// Search for stocks by symbol or name
    /// - Parameters:
    ///   - query: Search query (e.g., "AAPL" or "Apple")
    ///   - limit: Maximum number of results (default: 10, max: 50)
    /// - Returns: Array of matching stocks
    func searchStocks(query: String, limit: Int = 10) async throws -> [Stock] {
        let baseURL = "https://us-central1-goal-folio.cloudfunctions.net/searchStocks"
        
        guard let url = URL(string: baseURL) else {
            throw FirebaseServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "q": query,
            "limit": min(limit, 50)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        
        if !response.success {
            if let apiError = response.apiError {
                throw FirebaseServiceError.serverError(apiError)
            }
            throw FirebaseServiceError.serverError("Unknown error")
        }
        
        return response.results
    }
    
    /// Get detailed information about a specific stock
    /// - Parameter symbol: Stock symbol (e.g., "AAPL")
    /// - Returns: Stock details
    func getStock(symbol: String) async throws -> StockDetails {
        let data: [String: Any] = [
            "symbol": symbol.uppercased()
        ]
        
        let result = try await functions.httpsCallable("getStock").call(data)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result.data),
              let response = try? JSONDecoder().decode(StockDetailsResponse.self, from: jsonData) else {
            throw FirebaseServiceError.invalidResponse
        }
        
        if !response.success {
            throw FirebaseServiceError.serverError(response.error ?? "Unknown error")
        }
        
        guard let stockDetails = response.result else {
            throw FirebaseServiceError.noData
        }
        
        return stockDetails
    }
    
    // PRICE FUNCTIONS:
    
    /// Fetch intraday prices for a stock
    /// - Parameters:
    ///   - symbol: Stock symbol (e.g., "AAPL")
    ///   - interval: Time interval (default: "15min"). Options: "1min", "5min", "15min", "30min", "60min"
    ///   - outputSize: "compact" (last 100 data points) or "full" (default: "compact")
    ///   - adjusted: Whether to adjust for splits/dividends (default: true)
    ///   - extendedHours: Include extended trading hours (default: false)
    ///   - month: Specific month in YYYY-MM format (optional)
    /// - Returns: Array of stock candles with OHLCV data
    func fetchIntradayPrices(
        symbol: String,
        interval: String = "15min",
        outputSize: String = "compact",
        adjusted: Bool = true,
        extendedHours: Bool = false,
        month: String? = nil
    ) async throws -> [StockCandle] {
        guard !symbol.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PriceServiceError.emptySymbol
        }
        
        var data: [String: Any] = [
            "symbol": symbol.uppercased(),
            "interval": interval,
            "outputSize": outputSize,
            "adjusted": adjusted,
            "extendedHours": extendedHours
        ]
        
        if let month = month {
            data["month"] = month
        }
        
        let result = try await functions.httpsCallable("getIntradayPrices").call(data)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result.data) else {
            throw PriceServiceError.invalidResponse
        }
        
        guard let response = try? JSONDecoder().decode(IntradayPricesResponse.self, from: jsonData) else {
            throw PriceServiceError.decodingFailed
        }
        
        return response.candles
    }
    
    /// Get candles for the most recent open trading day
    /// - Parameters:
    ///   - symbol: Stock symbol (e.g., "AAPL")
    /// - Returns: Array of candles for the most recent trading day
    func getRecentOpenDayCandles(
        symbol: String,
    ) async throws -> [StockCandle] {
        guard !symbol.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PriceServiceError.emptySymbol
        }
        
        let data: [String: Any] = [
            "symbol": symbol.uppercased(),
        ]
        
        let result = try await functions.httpsCallable("getRecentOpenDay").call(data)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result.data) else {
            throw PriceServiceError.invalidResponse
        }
        
        guard let response = try? JSONDecoder().decode(RecentOpenDayResponse.self, from: jsonData) else {
            throw PriceServiceError.decodingFailed
        }
        
        return response.candles
    }
}

// MARK: - Usage Examples

/*
 
 // EXAMPLE 1: Search for stocks
 Task {
     do {
         let stocks = try await StockFirebaseService.shared.searchStocks(query: "Apple", limit: 10)
         for stock in stocks {
             print("\(stock.symbol): \(stock.name)")
         }
     } catch {
         print("Search failed: \(error.localizedDescription)")
     }
 }
 
 // EXAMPLE 2: Get stock details
 Task {
     do {
         let details = try await StockFirebaseService.shared.getStock(symbol: "AAPL")
         print("Stock: \(details.name)")
         print("Type: \(details.type)")
         print("Currency: \(details.currency)")
     } catch {
         print("Failed to get stock: \(error.localizedDescription)")
     }
 }
 
 // EXAMPLE 3: Fetch intraday prices
 Task {
     do {
         let candles = try await StockFirebaseService.shared.fetchIntradayPrices(
             symbol: "AAPL",
             interval: "15min",
             outputSize: "compact"
         )
         
         if let latestPrice = StockFirebaseService.getLatestPrice(from: candles) {
             print("Latest price: $\(latestPrice)")
         }
         
         if let change = StockFirebaseService.getPriceChange(from: candles) {
             print("Change: $\(change.change) (\(change.percentChange)%)")
         }
     } catch {
         print("Failed to fetch prices: \(error.localizedDescription)")
     }
 }
 
 // EXAMPLE 4: Get recent open day candles
 Task {
     do {
         let candles = try await StockFirebaseService.shared.getRecentOpenDayCandles(
             symbol: "AAPL",
             interval: "15min"
         )
         
         print("Trading day has \(candles.count) candles")
         for candle in candles {
             print("\(candle.time): Close $\(candle.close)")
         }
     } catch {
         print("Failed to get candles: \(error.localizedDescription)")
     }
 }
 
 // EXAMPLE 5: Fetch historical month data
 Task {
     do {
         let candles = try await StockFirebaseService.shared.fetchIntradayPrices(
             symbol: "AAPL",
             interval: "60min",
             outputSize: "full",
             month: "2024-11"
         )
         print("November 2024 has \(candles.count) hourly candles")
     } catch {
         print("Failed to fetch historical data: \(error.localizedDescription)")
     }
 }
 
 */

