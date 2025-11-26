//
//  PositionsHistorySection.swift
//  goal-folio
//
//  Created by Pratham S on 11/25/25.
//

import SwiftUI

struct PositionsHistory: View {
    @EnvironmentObject var positionsStore: PositionsStore
    
    @State private var isExpanded: Bool = true
    
    private var sortedHistory: [PositionsHistoryEntry] {
        positionsStore.positionsHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Transaction History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if sortedHistory.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(sortedHistory) { entry in
                                HistoryRow(entry: entry)
                                
                                if entry.id != sortedHistory.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let entry: PositionsHistoryEntry
    
    private var isPositive: Bool { entry.delta >= 0 }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.timestamp, relativeTo: DateHelper.getDate())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isPositive ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(entry.delta, format: .currency(code: "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isPositive ? Color.green : Color.red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Transactions Yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Your transaction history will appear here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

