//
//  RGBColor.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/1/26.
//

import Foundation

struct RGBColor: Equatable, Codable {
    var red: Double
    var green: Double
    var blue: Double

    /// Linear blend between two colors. t = 0 gives `from`, t = 1 gives `to`.
    static func interpolate(from: RGBColor, to: RGBColor, t: Double) -> RGBColor {
        let t = min(max(t, 0), 1)
        return RGBColor(
            red:   from.red   + (to.red   - from.red)   * t,
            green: from.green + (to.green - from.green) * t,
            blue:  from.blue  + (to.blue  - from.blue)  * t
        )
    }
}
