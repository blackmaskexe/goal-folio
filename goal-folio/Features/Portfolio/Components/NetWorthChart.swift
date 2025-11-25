//
//  NetWorthChart.swift
//  goal-folio
//
//  Created by Pratham S on 11/24/25.
//

import SwiftUI
import Charts

// MARK: - Time Range Options

enum TimeRange: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case fiveDays = "5D"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case yearToDate = "YTD"
    case oneYear = "1Y"
    case max = "Max"
    
    var id: String { rawValue }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Net Worth Chart View

struct NetWorthChart: View {
    @EnvironmentObject var positionsStore: PositionsStore
    
    @State private var selectedRange: TimeRange = .oneDay
    
    var body: some View {
        VStack(spacing: 16) {
            // Range Picker
            RangePicker(selected: $selectedRange)
            
            // Chart
            if chartData.isEmpty {
                EmptyChartView()
            } else {
                ChartView(data: chartData, range: selectedRange)
            }
        }
    }
    
    // MARK: - Get Chart Data
    
    private var chartData: [ChartDataPoint] {
        switch selectedRange {
        case .oneDay:
            return getIntradayData()
        case .fiveDays:
            return getDailyData(days: 5)
        case .oneMonth:
            return getDailyData(days: 30)
        case .sixMonths:
            return getSampledData(days: 180, maxPoints: 30)
        case .yearToDate:
            return getYearToDateData(maxPoints: 30)
        case .oneYear:
            return getDailyData(days: 365)
        case .max:
            return getAllData(maxPoints: 30)
        }
    }
    
    // MARK: - Data Retrieval Functions
    
    // Get intraday snapshots for today
    private func getIntradayData() -> [ChartDataPoint] {
        return positionsStore.netWorthData.todayIntraday.map { snapshot in
            ChartDataPoint(date: snapshot.timestamp, value: snapshot.netWorth)
        }
        .sorted { $0.date < $1.date }
    }
    
    // Get daily snapshots for the last N days
    private func getDailyData(days: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate date range
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return []
        }
        
        // Get all daily snapshots within range
        var dataPoints: [ChartDataPoint] = []
        
        for (dateString, value) in positionsStore.netWorthData.dailySnapshots {
            if let date = parseDateKey(dateString),
               date >= startDate && date <= today {
                dataPoints.append(ChartDataPoint(date: date, value: value))
            }
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    // Get year-to-date data with sampling
    private func getYearToDateData(maxPoints: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get January 1st of current year
        let year = calendar.component(.year, from: today)
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return []
        }
        
        // Get all daily snapshots from start of year
        var dataPoints: [ChartDataPoint] = []
        
        for (dateString, value) in positionsStore.netWorthData.dailySnapshots {
            if let date = parseDateKey(dateString),
               date >= startOfYear && date <= today {
                dataPoints.append(ChartDataPoint(date: date, value: value))
            }
        }
        
        let sorted = dataPoints.sorted { $0.date < $1.date }
        return sampleData(sorted, maxPoints: maxPoints)
    }
    
    // Get all available data with sampling
    private func getAllData(maxPoints: Int) -> [ChartDataPoint] {
        let dataPoints = positionsStore.netWorthData.dailySnapshots.map { (dateString, value) in
            let date = parseDateKey(dateString) ?? Date()
            return ChartDataPoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
        
        return sampleData(dataPoints, maxPoints: maxPoints)
    }
    
    // Get sampled data for a specific date range
    private func getSampledData(days: Int, maxPoints: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return []
        }
        
        var dataPoints: [ChartDataPoint] = []
        
        for (dateString, value) in positionsStore.netWorthData.dailySnapshots {
            if let date = parseDateKey(dateString),
               date >= startDate && date <= today {
                dataPoints.append(ChartDataPoint(date: date, value: value))
            }
        }
        
        let sorted = dataPoints.sorted { $0.date < $1.date }
        return sampleData(sorted, maxPoints: maxPoints)
    }
    
    // MARK: - Helper Functions
    
    // Parse date key "yyyy-MM-dd" into Date
    private func parseDateKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: key)
    }
    
    // Sample data to reduce to maxPoints by taking evenly spaced points
    private func sampleData(_ data: [ChartDataPoint], maxPoints: Int) -> [ChartDataPoint] {
        guard data.count > maxPoints else { return data }
        
        var sampled: [ChartDataPoint] = []
        let step = Double(data.count) / Double(maxPoints)
        
        for i in 0..<maxPoints {
            let index = Int(Double(i) * step)
            sampled.append(data[index])
        }
        
        // Always include the last point
        if let last = data.last {
            sampled.append(last)
        }
        
        return sampled
    }
}

// MARK: - Range Picker

private struct RangePicker: View {
    @Binding var selected: TimeRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        selected = range
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(selected == range ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .foregroundStyle(selected == range ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Chart View

private struct ChartView: View {
    let data: [ChartDataPoint]
    let range: TimeRange
    
    // Calculate value change
    private var change: Double {
        guard let first = data.first?.value, let last = data.last?.value else { return 0 }
        return last - first
    }
    
    private var changePercent: Double {
        guard let first = data.first?.value, first != 0 else { return 0 }
        return (change / first) * 100
    }
    
    private var isUp: Bool { change >= 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current value and change
            if let currentValue = data.last?.value {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(currentValue, format: .currency(code: "USD"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        ChangePill(change: change, percent: changePercent)
                    }
                }
            }
            
            // The actual chart
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(isUp ? Color.green : Color.red)
                .lineStyle(.init(lineWidth: 2))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            (isUp ? Color.green : Color.red).opacity(0.3),
                            (isUp ? Color.green : Color.red).opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(position: .trailing)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 200)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Change Pill

private struct ChangePill: View {
    let change: Double
    let percent: Double
    
    var isUp: Bool { change >= 0 }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .imageScale(.small)
            Text("\(change, format: .currency(code: "USD")) (\(percent, specifier: "%.2f")%)")
        }
        .font(.footnote.weight(.semibold))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background((isUp ? Color.green : Color.red).opacity(0.15), in: Capsule())
        .foregroundStyle(isUp ? Color.green : Color.red)
    }
}

// MARK: - Empty Chart View

private struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add positions to start tracking your net worth")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    NetWorthChart()
        .environmentObject(PositionsStore())
}
