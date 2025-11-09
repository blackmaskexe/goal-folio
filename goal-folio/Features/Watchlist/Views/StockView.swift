//
//  StockView.swift
//  goal-folio
//
//  Created by Pratham S on 11/6/25.
//

import SwiftUI

struct StockView: View {
    let symbol: String
    let name: String
    private let finnhubService = FinnhubService()
    @EnvironmentObject var tickerStore: TickerStore
        
    
    // Minimal inline sample data since PortfolioView.TimeRange is private to that file.
    private let sampleValues: [Double] = [0, 1.2, 0.8, 1.6, 2.0, 1.7, 2.4, 2.9, 2.6, 3.2]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Add stock to favorites") {
                    tickerStore.saveTicker(symbol: symbol, name: name)
                }
                if tickerStore.isTickerSaved(symbol: symbol) {
                    Button("Remove stock from favorites") {
                        tickerStore.removeTicker(symbol: symbol)
                    }
                }
                
            }
            
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(symbol.uppercased())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.vertical, 4)

            DummyLineChart()
                .frame(height: 64)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .navigationTitle(name)
        .onAppear {
            Task {
                do {
                    let stockData = try await finnhubService.fetchStockQuote(symbol: symbol)
                    print("Current price: ", stockData.c)
                } catch {
                    print("Error: ", error.localizedDescription)
                }
                
            }

        }

    }
}
