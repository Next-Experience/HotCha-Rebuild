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
        }
        .font(.pretendard(.bold, size: 24))
        .foregroundStyle(Color("gray50"))
        .padding(.horizontal, 30)

    }
}
