//
//  Extensions.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 3/25/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import Foundation
import HealthKit

let kHeartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

public let kHeartRateQuantityTypeIdentifier: HKQuantityTypeIdentifier = .heartRate
public let kHeartRateQuantityType = HKObjectType.quantityType(forIdentifier: kHeartRateQuantityTypeIdentifier)!

extension TimeInterval {
    
    var monthDayTime: String {
        get {
            let dateFormatter = Foundation.DateFormatter()
            let date = Date(timeIntervalSince1970: self)
            dateFormatter.dateFormat = "M.dd, h:mma"
            return dateFormatter.string(from: date).lowercased()
        }
    }
    
    var timeOnly: String {
        let dateFormatter = Foundation.DateFormatter()
        let date = Date(timeIntervalSince1970: self)
        dateFormatter.dateFormat = "h:mma"
        return dateFormatter.string(from: date).lowercased()
    }

    var formattedTime: String {
        get {
            let hours = Int(self) / 3600
            let minutes = Int(self) / 60 % 60
            let seconds = Int(self) % 60
            if hours > 0 {
                if minutes > 9 {
                    return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
                } else {
                    return String(format: "%01i:%02i:%02i", hours, minutes, seconds)
                }
            } else {
                if minutes > 9 {
                    return String(format: "%02i:%02i", minutes, seconds)
                } else {
                    return String(format: "%01i:%02i", minutes, seconds)
                }
            }
        }
    }
    
}
