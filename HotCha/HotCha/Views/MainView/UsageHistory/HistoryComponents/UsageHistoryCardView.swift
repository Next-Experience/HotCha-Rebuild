//
//  UsageHistorycard.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//
import SwiftUI

struct UsageHistoryCardView: View {
    @Environment(\.modelContext) private var modelContext
    var history: Usage_history
    
    var body: some View {
        VStack {
            VStack(spacing: 14) {
                HStack {
                    BookmarkBusNoView(busNo: history.bus_no, route_type: history.route_type)
                    Spacer()
                    Text(formattedDate(from: history.get_off_timestamp))
                        .font(.pretendard(.medium, size: 14))
                        .foregroundStyle(Color("gray500"))
                }
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("도착 정류장")
                        Text("하차 시간")
                        Text("차량 번호")
                        Text("운수사명")
                        Text("운수사 전화번호")
                    }
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray600"))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(history.destination_stop_name)
                        Text(formattedTime(from: history.get_off_timestamp))
                        Text(history.vehicle_no)
                        Text(history.operator_name ?? "정보 없음")
                        Text(history.operator_no ?? "정보 없음")
                    }
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray800"))
                    Spacer()
                }
                
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 30)
            
            Divider()
                .padding(0)
        }
        
    }
}



