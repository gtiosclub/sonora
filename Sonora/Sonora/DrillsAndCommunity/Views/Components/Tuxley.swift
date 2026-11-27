//
//  Tuxley.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/12/26.
//

import SwiftUI

/// The penguin mascot. Each mood is an image in Assets.xcassets named after its raw value.
enum TuxleyMood: String {
    case wave = "TuxleyWave"           // home greeting
    case happy = "TuxleyHappy"         // did well
    case thinking = "TuxleyThinking"   // did okay
    case sad = "TuxleySad"             // did poorly (no art yet, shows thinking)

    /// Mood for a 0-100 score
    init(score: Int) {
        switch score {
        case 70...: self = .happy
        case 50..<70: self = .thinking
        default: self = .sad
        }
    }
}

struct Tuxley: View {
    let mood: TuxleyMood

    var body: some View {
        Image(UIImage(named: mood.rawValue) != nil ? mood.rawValue : TuxleyMood.thinking.rawValue)
            .resizable()
            .scaledToFit()
    }
}
