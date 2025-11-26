//
//  HoldingsSection.swift
//  goal-folio
//
//  Created by Pratham S on 11/25/25.
//

import SwiftUI

struct HoldingsSection: View {
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
        HoldingCard(title: "Holdings") {
            
            if holdings.isEmpty {
                HStack {
                    Text("No positions yet. Use the + button to add.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
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

private struct HoldingCard<Content: View>: View {
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
