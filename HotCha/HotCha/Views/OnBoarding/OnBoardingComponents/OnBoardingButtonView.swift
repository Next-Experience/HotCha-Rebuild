//
//  OnBoardingButtonView.swift
//  HotCha
//
//  Created by 문재윤 on 3/12/25.
//

import SwiftUI

struct OnboardingButtonview: View {
    @State private var isTapped: Bool = false
    @AppStorage("OnBoarding_True") var OnBoardingTrue: Bool = false
    
    var body: some View {
        HStack {
            Spacer()
            Text("바로 시작하기")
                .padding(.vertical, 15)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(Color("gray900"))
            Spacer()
            
        }
        .background(isTapped ? Color("purplec") : Color("mainpurple"))
        .cornerRadius(8)
        .onTapGesture {
            withAnimation {
                isTapped = true
                
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isTapped = false
                    OnBoardingTrue = true
                    
                }
            }
        }
    }
}

#Preview {
    OnboardingButtonview()
}
