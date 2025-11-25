//
//  PortfolioView.swift
//  goal-folio
//
//  Created by Pratham S on 11/4/25.
//

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var positionsStore: PositionsStore
    @State private var showingAddPosition: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Net Worth Chart
                    NetWorthChart()

                    // Sections driven by positions
                    VStack(spacing: 16) {
                        // Use merged displayPositions so Cash appears as a single "Cash" row
                        HoldingsSection(positions: positionsStore.displayPositions)
                        // Removed AllocationSection card ("Top Weights")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPosition = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Position")
                }
            }
            .background(Color(.systemGroupedBackground))
            // Present AddPositionsView as a modal sheet
            .sheet(isPresented: $showingAddPosition) {
                NavigationStack {
                    AddPositionsView()
                        .environmentObject(positionsStore)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}

// MARK: - Holdings Section

private struct HoldingsSection: View {
    let positions: [Position]

    private struct Holding: Identifiable {
        let id = UUID()
        let symbol: String?
        let name: String
        let shares: Double
        let value: Double
    }

    private var holdings: [Holding] {
        positions.map { p in
            Holding(symbol: p.symbol,
                    name: p.name,
                    shares: p.quantity,
                    value: p.marketValue)
        }
        .sorted { $0.value > $1.value }
    }

    var body: some View {
        SectionCard(title: "Holdings") {
            if holdings.isEmpty {
                Text("No positions yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(holdings) { h in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(h.symbol ?? "—").font(.headline)
                                Text(h.name).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text("\(h.shares, specifier: "%.4f") units")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(h.value.formatted(.currency(code: "USD")))
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 8)
                    Divider().opacity(0.15)
                }
            }
        }
    }
}

// MARK: - Shared Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MainTabView()
}

