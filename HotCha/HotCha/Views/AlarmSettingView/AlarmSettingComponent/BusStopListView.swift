//
//  BusStopList.swift
//  HotCha
//
//  Created by Yeji Seo on 2/9/25.
//

import SwiftUI
import CoreLocation

struct BusStopListView: View {
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    
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
            isSelectDestinationMode: busStopSeoulViewModel.isSelectDestinationMode,
            currentFilteredStationID: busStopSeoulViewModel.currentFilteredStationID,
            viewModel: busStopSeoulViewModel
        )
        .ignoresSafeArea()
        .background(.gray900)
        .onAppear {
            if busStopSeoulViewModel.busStations.isEmpty {
                busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId) { success in
                    print("fetch bus stations 성공")
                }
            }
            // 현재 버스 위치
            //            busLocationViewModel.busRouteId = bus.busRouteId
        }
        .onReceive(nearestBusViewModel.$currBusStop) { newBusStop in
            checkNearestBusAndUpdateUI()
        }
        // 수정 버튼을 눌렀을 때 다시 매핑 하기위함
        .onChange(of: busStopSeoulViewModel.currentAlarmIndex) { _ in
            checkNearestBusAndUpdateUI()
        }
    }
    
    // 가장 가까운 버스를 확인하고 UI 업데이트
    private func checkNearestBusAndUpdateUI() {
        guard let currBusStop = nearestBusViewModel.currBusStop else { return }
        guard busStopSeoulViewModel.currentAlarmIndex != nil else { return }
        
        DispatchQueue.main.async {
            busStopSeoulViewModel.currentBusLocationMapping(nextStId: String(currBusStop.station))
        }
    }
}
