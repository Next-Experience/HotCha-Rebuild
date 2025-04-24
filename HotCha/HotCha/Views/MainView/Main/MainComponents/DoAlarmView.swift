//
//  DoAlarmView.swift
//  HotCha
//
//  Created by 문호 on 4/24/25.
//

import SwiftUI

struct DoAlarmView: View {
    var body: some View {
        HStack {
            Text("500")
            Text("남대문시장앞.이회영활동터")
                .font(.pretendard(.semibold, size: 16))
                .foregroundStyle(.gray900)
            Spacer()
            Image(systemName: "chevron.right")
                .frame(width: 20, height: 20)
                .foregroundStyle(.mainpurple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mainpurple.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mainpurple, lineWidth: 2)
                )
        )
    }
}

#Preview {
    DoAlarmView()
}
