//
//  TimeFormatting.swift
//  Sonora
//
//  Created by Dev Patel on 10/28/26.
//

import Foundation

extension TimeInterval {

    /// "m:ss", rounded to the nearest second
    var asClock: String {
        let total = Int(rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "m:ss.SS", with seconds rounded to two decimals
    var asPreciseClock: String {
        let minutes = Int(self) / 60
        let secs = self - Double(minutes * 60)
        return String(format: "%d:%05.2f", minutes, secs)
    }

    /// "X min Y sec", rounded to nearest second
    var asSpoken: String {
        let total = Int(rounded())
        return "\(total / 60) min \(total % 60) sec"
    }
}
