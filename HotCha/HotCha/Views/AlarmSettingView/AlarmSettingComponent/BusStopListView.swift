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
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    // 이전 nextStId 값을 저장하는 state 변수
    @State private var previousBusStId: String = ""
    
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
        .background(Color.gray900)
        .onAppear {
            busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId) { success in
                if success {
                    print("fetch bus stations success")
                }
            }
            // 현재 버스 위치
            busLocationViewModel.busRouteId = bus.busRouteId
        }
        // 변경 후 - onReceive 사용
        .onReceive(busLocationViewModel.$busPositions) { _ in
            checkNearestBusAndUpdateUI()
        }
    }
    
    // 가장 가까운 버스를 확인하고 UI 업데이트
    private func checkNearestBusAndUpdateUI() {
        guard let currentLocation = busLocationViewModel.locationVM.location,
              let nearestBus = busLocationViewModel.nearestBus(from: currentLocation) else {
            return
        }
        
        // 다음 정류장 ID가 변경된 경우에만 UI 업데이트 (중복 업데이트 방지)
//        if nearestBus.nextStId != previousBusStId {
            // 이전 ID 저장
            previousBusStId = nearestBus.nextStId
            
            // 메인 스레드에서 UI 업데이트 실행
            DispatchQueue.main.async {
                // BusStopSeoulViewModel의 currentBusLocationMapping 메소드 호출하여 UI 업데이트
                if !nearestBus.nextStId.isEmpty {
                    busStopSeoulViewModel.currentBusLocationMapping(nextStId: nearestBus.nextStId)
                }
            }
//        }
    }
}
