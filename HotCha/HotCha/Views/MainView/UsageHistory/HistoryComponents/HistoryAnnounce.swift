//
//  Historyannouncement.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//
import SwiftUI

struct HistoryAnnounce: View {
    var body: some View {
        VStack {
            VStack(spacing: 8) {
                HStack {
                    Text("버스에서 물건을 잃어버렸다면?")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("gray900"))
                    Spacer()
                }
                
                HStack(spacing: 0) {
                    Text("분실물 찾는 방법 알아보기")
                        .font(.pretendard(.semibold, size: 14))
                        .foregroundStyle(Color("lostitem"))
                    Image("chevron-right-blue")
                        
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(Color("gray150"))
        .cornerRadius(8)
    }
}



struct Historyannouncement_Previews: PreviewProvider {
    static var previews: some View {
        HistoryAnnounce()
    }
}
