//
//  StocksChart.swift
//  goal-folio
//
//  Created by Pratham S on 11/9/25.
//

import SwiftUI
import Charts

struct StocksChart: View {
    let stockCandles: [StockCandle]

    // iOS 17+ simple selection on X axis (Date)
    @State private var selectedDate: Date?

    // Basic derived values
    private var openPrice: Double? { stockCandles.first?.close }
    private var latest: StockCandle? { stockCandles.last }
    private var selectedCandle: StockCandle? {
        guard let date = selectedDate else { return nil }
        return nearest(to: date)
    }

    // Use either the selected point (when scrubbing) or the latest
    private var displayCandle: StockCandle? {
        selectedCandle ?? latest
    }

    // Up or down vs open determines color
    private var isUp: Bool {
        guard let open = openPrice, let now = displayCandle?.close else { return true }
        return now >= open
    }

    // Minimal y-domain with a bit of padding
    private var yDomain: ClosedRange<Double> {
        let values = stockCandles.map(\.close)
        guard let minV = values.min(), let maxV = values.max(), minV != maxV else {
            let p = values.first ?? 0
            return (p * 0.99)...(p * 1.01)
        }
        let pad = max((maxV - minV) * 0.04, 0.01)
        return (minV - pad)...(maxV + pad)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with current price and change vs open
            if let c = displayCandle, let open = openPrice {
                let change = c.close - open
                let pct = open != 0 ? (change / open) * 100 : 0
                let up = change >= 0

                HStack(spacing: 10) {
                    Text(c.close, format: .currency(code: "USD"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("\(up ? "+" : "")\(change, format: .currency(code: "USD")) (\(pct, specifier: "%.2f")%)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(up ? .green : .red)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background((up ? Color.green : Color.red).opacity(0.12), in: Capsule())

                    Spacer()
                }
                .animation(.default, value: selectedDate)
            }

            // Simple line + shaded area; minimal selection circle while dragging
            Chart {
                // Area fill (color depends on up/down vs open)
                ForEach(stockCandles, id: \.id) { candle in
                    AreaMark(
                        x: .value("Time", candle.time),
                        y: .value("Close", candle.close)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle((isUp ? Color.green : Color.red).opacity(0.18))
                }

                // Line
                ForEach(stockCandles, id: \.id) { candle in
                    LineMark(
                        x: .value("Time", candle.time),
                        y: .value("Close", candle.close)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(isUp ? .green : .red)
                    .lineStyle(.init(lineWidth: 2))
                }

                // Minimal selection dot only while dragging
                if let s = selectedCandle {
                    PointMark(
                        x: .value("Time", s.time),
                        y: .value("Close", s.close)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(40)
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden) // keep minimal
            .chartYAxis {
                AxisMarks(position: .trailing)
            }
            .frame(height: 220)
            // iOS 17+ selection
            .chartXSelection(value: $selectedDate)
            // Keep drawing contained to the plot area
            .chartPlotStyle { plot in
                plot
                    .contentShape(Rectangle())
                    .clipped()
            }
        }
    }

    // MARK: - Helpers

    private func nearest(to date: Date) -> StockCandle? {
        guard !stockCandles.isEmpty else { return nil }
        return stockCandles.min { a, b in
            abs(a.time.timeIntervalSince(date)) < abs(b.time.timeIntervalSince(date))
        }
    }
}
