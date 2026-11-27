//
//  ComingSoonView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/14/26.
//

import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            SonoraTopBar(title: title) { BackButton() } trailing: { Color.clear.frame(width: 44) }
            Spacer()
            Image(systemName: "hammer.fill").font(.largeTitle).foregroundStyle(ProfilePalette.lavender)
            Text("Coming soon").font(.title3.weight(.semibold)).foregroundStyle(ProfilePalette.deepPlum)
            Spacer()
        }
        .padding(.horizontal, 16)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
