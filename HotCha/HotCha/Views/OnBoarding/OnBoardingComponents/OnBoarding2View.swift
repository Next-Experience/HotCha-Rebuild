//
//  OnBoarding1.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct OnBoarding2View: View {
    var body: some View {
        VStack {
            HStack {
                Text("상황에 맞는")
                Spacer()
            }
            HStack {
                Text("알림 소리를 설정해요")
                Spacer()
            }
            Spacer()
            Image("Onboarding3")
//                .resizable()
                .padding(.bottom, 48)
                .padding(.top, 0)
        }
        .font(.pretendard(.bold, size: 24))
        .foregroundStyle(Color("gray50"))
        .padding(.horizontal, 30)

    }
}


#Preview {
    OnBoardingView()
}
