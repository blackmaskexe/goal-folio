//
//  LineChart.swift
//  goal-folio
//
//  Created by Pratham S on 11/6/25.
//

import SwiftUI

struct MiniLineChart: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = max(values.max() ?? 1, 1)
            let minVal = values.min() ?? 0
            let span = max(maxVal - minVal, 1)
            let stepX = values.count > 1 ? width / CGFloat(values.count - 1) : 0

            ZStack {
                // Grid lines
                VStack {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 1)
                            .frame(maxHeight: .infinity, alignment: .top)
                        Spacer()
                    }
                }

                // Line path
                Path { path in
                    guard !values.isEmpty else { return }
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * stepX
                        let yRatio = (v - minVal) / span
                        let y = height - CGFloat(yRatio) * height
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Fill under line
                Path { path in
                    guard !values.isEmpty else { return }
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * stepX
                        let yRatio = (v - minVal) / span
                        let y = height - CGFloat(yRatio) * height
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(Color.accentColor.opacity(0.12))
            }
        }
    }
}

#Preview {
    MiniLineChart(values: [0, 2, 1, 3, 2.5, 4, 3.5, 5])
        .frame(height: 160)
        .padding()
}
