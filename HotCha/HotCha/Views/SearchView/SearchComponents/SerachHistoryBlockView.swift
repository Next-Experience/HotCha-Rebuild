//
//  SerachHistoryBlockView.swift
//  HotCha
//
//  Created by 문재윤 on 2/28/25.
//

import SwiftUI

struct SerachHistoryBlockView: View {
    var history: Usage_history
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SearchBusUtil.CustomBusNoView(busNo: history.bus_no, routeType: history.route_type)
              
                BusTypeLabelView(busNo: history.bus_no, routeType: history.route_type)
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
