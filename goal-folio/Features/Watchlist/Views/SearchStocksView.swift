//
//  SearchStocksView.swift
//  goal-folio
//
//  Created by Pratham S on 11/20/25.
//

import SwiftUI

struct SearchStocksView: View {
    @EnvironmentObject var loadingManager: LoadingManager
    @EnvironmentObject var stockStore: StockStore

    @State private var query: String = ""
    @State private var results: [Stock] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @FocusState private var isFieldFocused: Bool

    private var showSuggestions: Bool {
        isFieldFocused && query.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            // Custom Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search a Stock", text: $query)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .focused($isFieldFocused)
                    .onChange(of: query) {
                        debounceSearch()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        results = StaticStockData.all
                        isFieldFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)

            // Content
            Group {
                if showSuggestions {
                    SuggestionsList(stocks: StaticStockData.all)
                } else {
                    ResultsList(stocks: results, isLoading: loadingManager.isLoading, query: query)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start with suggestions visible and focus the field
            results = StaticStockData.all
            isFieldFocused = true
        }
        .onDisappear {
            searchTask?.cancel()
            searchTask = nil
        }
    }

    // MARK: - Debounce and search

    private func debounceSearch() {
        searchTask?.cancel()
        if query.isEmpty {
            // When cleared, show suggestions
            results = StaticStockData.all
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            await performSearch()
        }
    }

    @MainActor
    private func performSearch() async {
        do {
            loadingManager.show()
            let stocks = try await StockFirebaseService.shared.searchStocks(query: query, limit: 10)
            results = stocks
            loadingManager.hide()
        } catch {
            print("Search error: \(error)")
            results = []
            loadingManager.hide()
        }
    }
}

// MARK: - Subviews for Search Screen

private struct SuggestionsList: View {
    let stocks: [Stock]

    var body: some View {
        List {
            Section("Suggestions") {
                ForEach(stocks, id: \.self) { stock in
                    NavigationLink {
                        StockView(symbol: stock.symbol, name: stock.name)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.symbol).font(.headline)
                            Text(stock.name).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct ResultsList: View {
    let stocks: [Stock]
    let isLoading: Bool
    let query: String

    var body: some View {
        List {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }
            } else if stocks.isEmpty {
                // Only show "No results" when not loading and the user has typed something
                if !query.isEmpty {
                    Text("No results")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(stocks, id: \.self) { stock in
                    NavigationLink {
                        StockView(symbol: stock.symbol, name: stock.name)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.symbol).font(.headline)
                            Text(stock.name).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
