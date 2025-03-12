//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 3/12/25.
//
import SwiftUI

struct OnboardingPointview: View {
    
    @Binding var OnBoardingTab: Int
    
    var body: some View {
        HStack(spacing: 4) {
        ForEach(0..<4) { index in
            
            if index == OnBoardingTab {
                Capsule()
                    .frame(width: 16, height: 8)
                    .foregroundColor(Color("mainpurple"))
                    .animation(.easeInOut(duration: 1), value: OnBoardingTab)
            } else {
                    Circle()
                        .frame(width: 8)
                        .foregroundColor(Color("gray500"))
                        .animation(.easeInOut(duration: 1), value: OnBoardingTab)
                }
            }
            Spacer()
        }
    }
}
