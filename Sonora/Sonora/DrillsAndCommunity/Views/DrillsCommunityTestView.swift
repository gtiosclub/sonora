//
//  TestView.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 10/11/26.
//

import SwiftUI


struct DrillsCommunityTestView: View {
    
    @State private var skillProfile: SkillProfile?
    
    var body: some View {
        Button("Test Functions Here") {
            Task {
                do {
                    skillProfile = try await SkillProfileService.fetch(for: "0EGGJvUjGsQwYAa77CFXx47Dnpy2")
                } catch {
                    print("Error found: \(String(reflecting: error))")
                }
            }
        }
        
        Text(skillProfile?.id ?? "No Data")
        Text(skillProfile?.clarity.summary ?? "No Data")
        Text(skillProfile?.content.summary ?? "No Data")
        Text(skillProfile?.confidence.summary ?? "No Data")
        Text(skillProfile?.engaging.summary ?? "No Data")
        

    }
}

#Preview {
    DrillsCommunityTestView()
}
