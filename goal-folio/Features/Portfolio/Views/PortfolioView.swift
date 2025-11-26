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
                        HoldingsDisplay(positions: positionsStore.displayPositions)
                        // Removed AllocationSection card ("Top Weights")
                    }
                    .padding(.horizontal)
                    
                    PositionsHistory()
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


#Preview {
    MainTabView()
}

