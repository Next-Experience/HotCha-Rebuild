//
//  OnBoarding1.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct OnBoarding0View: View {
    var body: some View {
        VStack {
            HStack {
                Text("버스 실시간 이동경로를 ")
                Spacer()
            }
            HStack {
                Text("확인해요.")
                Spacer()
            }
            Spacer()
            Image("Onboarding1")
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
