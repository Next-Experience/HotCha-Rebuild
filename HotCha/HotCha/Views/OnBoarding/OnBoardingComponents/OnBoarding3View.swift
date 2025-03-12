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
        }
        .font(.pretendard(.bold, size: 24))
        .foregroundStyle(Color("gray50"))
        .padding(.horizontal, 30)
    }
}
