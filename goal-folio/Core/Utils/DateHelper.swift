//
//  DateHelper.swift
//  goal-folio
//
//  Created by Pratham S on 11/18/25.
//

import Foundation

struct DateHelper {
    // return a formatted date string (yyyy-mm-dd)
    // all of them are optional parameters
    static func getFormattedDate(for date: Date? = nil,
                                   timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!,
                                   locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let baseDate = date ?? Date()
        let dayStart = calendar.startOfDay(for: baseDate)

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dayStart)
    }
}
