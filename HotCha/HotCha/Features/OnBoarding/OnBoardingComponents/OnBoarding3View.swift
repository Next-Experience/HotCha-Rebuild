//
//  OnBoarding1.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct OnBoarding3View: View {
    var body: some View {
        VStack {
            HStack {
                Text("원할한 이용을 위해")
                Spacer()
            }
            HStack {
                Text("위치 권한과 알림권한은")
                Spacer()
            }
            HStack {
                Text("허용해주세요")
                Spacer()
            }
            Spacer()
            Image("Onboarding4")
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
