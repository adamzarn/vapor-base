//
//  PhotoTimestamp.swift
//  
//
//  Created by Adam Zarn on 9/17/21.
//

import Foundation

struct PhotoTimestamp {
    static var current: String {
        let components: Set<Calendar.Component> = [.year,
                                                   .month,
                                                   .day,
                                                   .hour,
                                                   .minute,
                                                   .second,
                                                   .nanosecond]
        let comps = Calendar.current.dateComponents(components, from: Date())
        guard let year = comps.year,
              let month = comps.month,
              let day = comps.day,
              let hour = comps.hour,
              let minute = comps.minute,
              let second = comps.second,
              let nanosecond = comps.nanosecond else { return "" }
        return "\(year)-\(month)-\(day)-\(hour)-\(minute)-\(second)-\(nanosecond)"
    }
}
