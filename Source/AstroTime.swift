//
//  AstroTime.swift
//  AstronomyKit
//
//  Created by Thomas Wetmore on 8/25/2014.
//  Last changed on 3/30/2022.
//  Copyright (c) 2014-2022 DeadEnds Software. All rights reserved.
//

import Foundation

// AstroTime values are dates and times used in astronomical computation.
//--------------------------------------------------------------------------------------------------
public struct AstroTime : CustomStringConvertible, Comparable {

    // MARK: Stored Instance Properties
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let second: Double

    // MARK: Computed Instance Properties
    // Return string representation of this AstroTime.
    public var description: String {
        return "\(AstroTime.monthAbbrevs[month-1]) \(day), \(year) \(hour):\(minute):\(second.format(0))"
    }

    // MARK: Type Methods
    // Return valid AstroTime or nil. Use this method when argument checking is required.
    public static func validTime (year: Int, month: Int, day: Int, hour: Int, minute: Int,
                                  second: Double) -> AstroTime? {
        if month < 1 || month > 12 || year < 500 || year > 5000 || day < 1 || day > 31 {
            return nil
        }
        if hour < 0 || hour > 24 || minute < 0 || minute > 60 || second < 0.0 || second > 60.0 {
            return nil
        }
        return AstroTime(year: year, month: month, day: day, hour: hour, minute: minute,
                         second: second)
    }

    // Return valid AstroTime or nil. Use this method when argument checking is required.
    public static func validTime (year: Int, month: String, day: Int) -> AstroTime? {
        if year < 500 || year > 5000 || day < 1 || day > 31 {
            return nil
        }
        if let monthIndex = monthMap[month] {
            return AstroTime(year: year, month: monthIndex, day: day)
        }
        else {
            return nil
        }
    }

    // MARK: Initializers
    // Init AstroTime with all components. Assumes valid arguments.
    public init (year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Double) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    // Init AstroTime from date information. Assumes valid arguments.
    public init (year: Int, month: Int, day: Int) {
        self.init(year: year, month: month, day: day, hour: 0, minute: 0, second: 0.0)
    }

    // Init AstroTime from year, month string and day. Assumes valid arguments.
    public init (year: Int, month: String, day: Int) {
        let monthIndex = AstroTime.monthMap[month]
        self.init(year: year, month: monthIndex!, day: day)
    }

    // Init AstroTime from a modified julian day number.
    public init (julian: Double) {
        let a: Int = Int(julian) + 2400001
        var b: Int
        var c: Int
        if a < 2299161 {
            b = 0
            c = Int(a) + 1524
        } else {
            b = Int((Float(a) - 1867216.25)/36524.25)
            c = Int(a) + b - (b/4) + 1525
        }
        let d = Int((Double(c) - 122.1)/365.25)
        let e = 365*d + d/4
        let f = Int(Double(c - e)/30.6001)
        let day = c - e - Int(30.6001*Double(f))
        let month = f - 1 - 12*(f/14)
        let year = d - 4715 - (7 + month)/10
        var fraction = julian - trunc(julian)
        fraction *= 24
        let hour = Int(fraction)
        fraction -= Double(hour)
        fraction *= 60
        let minute = Int(fraction)
        let second = 60.0*(fraction - Double(minute))

        self.init(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }

    // Return modified Julian date of this AstroTime.
    public func toJulian () -> Double {
        var m = month
        var y = year
        if m <= 2 {
            m += 12
            y -= 1
        }
        var b: Int
        if (10000*y + 100*m + day) <= 15821004 {
            b = -2 + ((y + 4716)/4) - 1179 // Julian calendar
        } else {
            b = (y/400) - (y/100) + (y/4)  // Gregorian calendar
        }
        let fraction = ((second/60.0 + Double(minute))/60.0 + Double(hour))/24.0
        let dayno = 365*y - 679004 + b + Int(30.6001*Double(m + 1)) + day
        return Double(dayno) + fraction
    }

    // Return AstroTime of the current time.
    static func now () -> AstroTime {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                 from: date)
        return AstroTime(year: components.year!, month: components.month!, day: components.day!,
            hour: components.hour!, minute: components.minute!, second: Double(components.second!))
    }

    // Day part of this AstroTime as an integer.
    public var dayInteger: Int {
        year*10000 + month*100 + day
    }

    // Time part of this AstroTime in seconds.
    public var seconds: Double {
        Double((hour*60 + minute)*60) + second
    }

    // Month abbreviation of this AstroTime.
    public var monthAbbrev: String? {
        month >= 1 && month <= 12 ? AstroTime.monthAbbrevs[month] : nil
    }

    // Month name of this AstroTime.
    public var monthName: String? {
        month >= 1 && month <= 12 ? AstroTime.monthNames[month] : nil
    }

    // Day of year of this AstroTime.
    public var dayOfYear: Int {
        var dayOfYear = AstroTime.monthOffsets[month - 1] + day
        if month > 2 && isLeapYear(year: year) { dayOfYear += 1 }
        return dayOfYear
    }
}

// Return whether a year is a leap year.
func isLeapYear (year: Int) -> Bool {
    if year % 4 != 0 { return false }
    if year % 400 == 0 { return true }
    if year % 100 == 0 { return false }
    return true
}

// Return whether an AstroTime is less (earlier) than another.
public func < (lhs: AstroTime, rhs: AstroTime) -> Bool {
    let left = lhs.dayInteger
    let right = rhs.dayInteger
    if left != right { return left < right }
    let leftSecond = lhs.seconds
    let rightSecond = rhs.seconds
    return leftSecond < rightSecond
}

// Return whether an AstroTime is equal to another.
public func == (lhs: AstroTime, rhs: AstroTime) -> Bool {
    let left = lhs.dayInteger
    let right = rhs.dayInteger
    if left != right { return false }
    return lhs.second == rhs.seconds
}

// Return the difference between two AstroTime values as double day value.
func - (lhs: AstroTime, rhs: AstroTime) -> Double {
    lhs.toJulian() - rhs.toJulian()
}

// Extension of AstroTime that defines constants.
extension AstroTime {
    static let monthAbbrevs = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
                               "Sep", "Oct", "Nov", "Dec"]
    static let monthNames = ["January", "February", "March", "April", "May", "June",
                        "July", "August", "September", "October", "November", "December"]
    static let monthOffsets = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    static let monthMap: Dictionary<String, Int> =
        ["January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6, "July": 7,
         "August": 8, "September": 9, "October": 10, "November": 11, "December": 12, "Jan": 1,
         "Feb": 2, "Mar": 3, "Apr": 4, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11,
         "Dec": 12, "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6, "jul": 7, "aug": 8,
         "sep": 9, "oct": 10, "nov": 11, "dec": 12]
}
