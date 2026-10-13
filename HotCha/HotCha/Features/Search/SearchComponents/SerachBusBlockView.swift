//
//  SerachHistoryBlockView.swift
//  HotCha
//
//  Created by 문재윤 on 2/28/25.
//

import SwiftUI

struct SerachBusBlockView: View {
    var history: Usage_history
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
              BookmarkBusNoView(busNo: history.bus_no, route_type: history.route_type)
              
              Text("\(history.city_code) \(history.route_type)  버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
                Spacer()
                  
            }
            .padding(.top, 16)
            HStack {
                Text("\(history.destination_stop_name)")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray900"))
                Spacer()
            }
            .padding(.bottom, 6)
            Divider()
                .padding(0)
                .foregroundStyle(Color("gray100"))
        }
    }
}
