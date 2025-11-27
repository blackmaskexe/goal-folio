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
    static func getFormattedDate(for date: Date? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date ?? getDate())
    }
    
    static func getDateFromFormattedDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    static func getDate() -> Date {
            return Date()
//        return Calendar.current.date(byAdding: .day, value: 49, to: Date()) ?? Date()
    }
}
