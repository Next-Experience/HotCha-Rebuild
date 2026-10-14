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
