//
//  BusStopList.swift
//  HotCha
//
//  Created by Yeji Seo on 2/9/25.
//

import SwiftUI

struct BusStopListView: View {
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    
    var body: some View {
        // 드래그 가능한 UIKit 테이블 뷰 사용
        DraggableBusStopList(
            busStops: busStopSeoulViewModel.busStations,
            onArrivalStationChanged: { index in
                busStopSeoulViewModel.selectDestinationStation(destIndex: index)
            },
            onAlarmStationChanged: { index in
                busStopSeoulViewModel.selectAlarmStation(alarmIndex: index)
            },
            isDraggingDestination: busStopSeoulViewModel.isDraggingDestination,
            currentFilteredStationID: busStopSeoulViewModel.currentFilteredStationID,
                        viewModel: busStopSeoulViewModel
        )
        .ignoresSafeArea()
        .background(Color.gray900)
        .onAppear {
            busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId)
        }
    }
}

