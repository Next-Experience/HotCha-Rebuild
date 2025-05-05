//
//  DoAlarmView.swift
//  HotCha
//
//  Created by 문호 on 4/24/25.
//

import SwiftUI

struct DoAlarmView: View {
    @Binding var bus: Bus_info_seoul // 선택된 버스 정보
    @Binding var cityCode: Int
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."

    var body: some View {
        VStack {
            HStack {
                Text("목적지까지 \(remainingStops)")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("gray900"))
                
                Text("") // AlarmStatusView AlertStopsSection 구조체 참조
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("mainpurple"))
                
//                Text("정거장 남았어요")
//                    .font(.pretendard(.bold, size: 24))
//                    .foregroundStyle(Color("gray900"))
                Spacer()
            }
            
            HStack {
                SearchBusUtil.CustomBusNoView(busNo: bus.busRouteNm, routeType:bus.routeType)
                if let index = busStopSeoulViewModel.currentDestinationIndex {
                    Text(busStopSeoulViewModel.busStations[index].stationNm)
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(.gray900)
                        .padding(.leading, 8)
                }
                
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
}

