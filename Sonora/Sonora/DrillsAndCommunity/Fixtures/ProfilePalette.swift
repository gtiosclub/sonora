//
//  ProfilePalette.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/16/26.
//

import SwiftUI

enum ProfilePalette {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }

    static let lavender      = rgb(196, 195, 227)  // #C4C3E3  cards + highlights
    static let deepPlum      = rgb(80, 78, 118)    // #504E76  primary buttons, titles
    static let softBeige     = rgb(253, 248, 226)  // #FDF8E2  backgrounds
    static let calmGreen     = rgb(163, 181, 101)  // #A3B565  streaks + progress
    static let lightApricot  = rgb(252, 221, 157)  // #FCDD9D  warm cards (verify in Figma)
    static let brightOrange  = rgb(241, 100, 46)   // #F1642E  calls to action
    static let primaryText   = rgb(36, 36, 36)     // #242424
    static let secondaryText = rgb(81, 81, 81)     // #515151
}
