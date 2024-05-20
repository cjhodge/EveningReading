//
//  DateExtensions.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import Foundation
import SwiftUI



extension Date {

    func timeRemaining() -> String {
        let date = NSDate()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .month, .year, .day], from: date as Date)
        let currentDate = calendar.date(from: components)
        let expiringTime = self.addingTimeInterval(86400)
        let CompetitionDayDifference = calendar.dateComponents([.day, .hour, .minute], from: currentDate!, to: expiringTime)
        let hoursLeft = CompetitionDayDifference.hour
        let minutesLeft = CompetitionDayDifference.minute
        var remaining = (hoursLeft ?? 0) > 0 ? "\(hoursLeft ?? 0) Hrs, " : ""
        remaining = remaining + "\(minutesLeft ?? 0) Mins"
        if remaining.hasPrefix("-") {
            remaining = "Now"
        }
        return remaining
    }
    
    func percentRemaining() -> CGFloat {
        let date = NSDate()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .month, .year, .day], from: date as Date)
        let currentDate = calendar.date(from: components)
        let expiringTime = self.addingTimeInterval(86400)
        let elapsed = expiringTime.timeIntervalSince(currentDate!)
        let percent = ((elapsed / 86400) * 10).rounded(.towardZero) / 10
        let percentWidth = (235.0 * percent).rounded(.towardZero)
        return 235.0 - CGFloat(percentWidth)
    }
    
    func timeSince() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        formatter.maximumUnitCount = 1
        let timeSinceValue = String(format: formatter.string(from: self, to: Date()) ?? "", locale: .current)
                            .replacingOccurrences(of: "day", with: " day")
                            .replacingOccurrences(of: "month", with: " month")
                            .replacingOccurrences(of: "year", with: " year")
        return timeSinceValue
    }
    
}
