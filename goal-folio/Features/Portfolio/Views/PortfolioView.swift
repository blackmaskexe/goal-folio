//
//  PortfolioView.swift
//  goal-folio
//
//  Created by Pratham S on 11/4/25.
//
// (M1.1) Static placeholder screen -> now backed by PositionsStore and daily market value series

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var positionsStore: PositionsStore

    @State private var selectedRange: TimeRange = .oneD

    // Derived state from store
    private var series: [TimeSeriesPoint] {
        // Build a sorted series from dailyMarketValueByDate filtered by selected range
        let all = positionsStore.dailyMarketValueByDate.compactMap { (key, value) -> TimeSeriesPoint? in
            guard let date = DateParser.parseDayKey(key) else { return nil }
            return TimeSeriesPoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }

        let interval = selectedRange.dateIntervalEndingNow()
        return all.filter { interval.contains($0.date) }
    }

    private var chartValues: [Double] {
        // Transform to values normalized like before (min-based), but keep absolute for summary
        let vals = series.map(\.value)
        guard let minVal = vals.min() else { return [] }
        return vals.map { $0 - minVal }
    }

    private var currentValue: Double {
        series.last?.value ?? positionsStore.totalMarketValue
    }

    private var changeValue: Double {
        guard let first = series.first?.value, let last = series.last?.value else { return 0 }
        return last - first
    }

    private var changePercent: Double {
        guard let first = series.first?.value, first != 0 else { return 0 }
        return (changeValue / first) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Chart + Range Picker Card
                    VStack(alignment: .leading, spacing: 12) {
                        // Time range selector
                        RangePicker(selected: $selectedRange) {
                            // No explicit animation of data here; SwiftUI will animate chart area
                        }

                        // Lightweight "chart"
                        LineChart(values: chartValues)
                            .frame(height: 180)
                            .animation(.easeInOut, value: chartValues)

                        // Portfolio value
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio Value")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(currentValue.formatted(.currency(code: "USD")))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                ChangePill(change: changeValue, percent: changePercent)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Sections driven by positions
                    VStack(spacing: 16) {
                        HoldingsSection(positions: positionsStore.savedPositions)
                        // Removed AllocationSection card ("Top Weights")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Portfolio")
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            // Ensure today value is present; PositionsStore already updates on init/CRUD.
            // If you later fetch live quotes, call a store method to refresh today’s value here.
        }
    }
}

// MARK: - Time Series Types and Parser

private struct TimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private enum DateParser {
    // Parse "yyyy-MM-dd" day keys in UTC into Date at start of day UTC.
    static func parseDayKey(_ key: String) -> Date? {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: key)
    }
}

// MARK: - Time Range

private enum TimeRange: String, CaseIterable, Identifiable {
    case oneD = "1D"
    case fiveD = "5D"
    case oneM = "1M"
    case sixM = "6M"
    case ytd = "YTD"
    case oneY = "1Y"

    var id: String { rawValue }

    func dateIntervalEndingNow(now: Date = Date()) -> DateInterval {
        let cal = Calendar(identifier: .gregorian)
        switch self {
        case .oneD:
            let start = cal.date(byAdding: .day, value: -1, to: now) ?? now
            return DateInterval(start: start, end: now)
        case .fiveD:
            let start = cal.date(byAdding: .day, value: -5, to: now) ?? now
            return DateInterval(start: start, end: now)
        case .oneM:
            let start = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return DateInterval(start: start, end: now)
        case .sixM:
            let start = cal.date(byAdding: .month, value: -6, to: now) ?? now
            return DateInterval(start: start, end: now)
        case .ytd:
            let startOfYear = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: 1, day: 1)) ?? now
            return DateInterval(start: startOfYear, end: now)
        case .oneY:
            let start = cal.date(byAdding: .year, value: -1, to: now) ?? now
            return DateInterval(start: start, end: now)
        }
    }
}

// MARK: - Range Picker

private struct RangePicker: View {
    @Binding var selected: TimeRange
    var onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    guard selected != range else { return }
                    selected = range
                    onChange()
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(selected == range ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - Change Pill

private struct ChangePill: View {
    let change: Double
    let percent: Double

    var isUp: Bool { change >= 0 }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .imageScale(.small)
            Text("\(change, format: .currency(code: "USD"))) (\(percent, specifier: "%.2f")%)")
        }
        .font(.footnote.weight(.semibold))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background((isUp ? Color.green : Color.red).opacity(0.15), in: Capsule())
        .foregroundStyle(isUp ? Color.green : Color.red)
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
