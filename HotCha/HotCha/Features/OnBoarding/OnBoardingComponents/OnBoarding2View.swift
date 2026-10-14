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
                Text("무음 모드에서도")
                Spacer()
            }
            HStack {
                Text("알람으로 깨워 드려요")
                Spacer()
            }
            Spacer()
            Image("Onboarding3")
//                .resizable()
                .padding(.bottom, 48)
                .padding(.top, 0)
        }
        .font(.pretendard(.bold, size: 24))
        .foregroundStyle(.primary)
        .padding(.horizontal, 30)

    }
}


#Preview {
    OnBoardingView()
}
