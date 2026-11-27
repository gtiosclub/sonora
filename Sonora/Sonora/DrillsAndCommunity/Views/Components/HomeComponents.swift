//
//  HomeComponents.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/12/26.
//

import SwiftUI

struct HomeProgressBar: View {
    let score: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HomeColor.track)
                Capsule().fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(score, 0), 100)) / 100)
            }
        }
        .frame(height: 12)
    }
}
