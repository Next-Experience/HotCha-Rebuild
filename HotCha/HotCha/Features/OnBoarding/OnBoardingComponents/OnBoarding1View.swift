//
//  OnBoarding1.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct OnBoarding1View: View {
    var body: some View {
        VStack {
            HStack {
                Text("하차 정류장을 설정하고,")
                Spacer()
            }
            HStack {
                Text("원하는 위치에서 알림을 받아요")
                Spacer()
            }
            Spacer()
            Image("Onboarding2")
                // 그림은 원래 크기(333×470pt)를 넘지 않게, 남는 자리에 맞춰 줄인다. 키가 작은 화면(접은 아이폰 듀오)에서 제목을 밀어내지 않는다.
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 333, maxHeight: 470)
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
