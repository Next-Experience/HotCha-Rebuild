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
        .background(Color.gray900)
        .onAppear {
            if busStopSeoulViewModel.busStations.isEmpty {
                busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId) { success in
                    print("fetch bus stations 성공")
                }
            }
            // 현재 버스 위치
            //            busLocationViewModel.busRouteId = bus.busRouteId
        }
        .onReceive(nearestBusViewModel.$currBusStop) { _ in
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
            busStopSeoulViewModel.currentBusLocationMapping(nextStId: currBusStop.station)
        }
        
        
        //        guard let currentLocation = busLocationViewModel.locationVM.location,
        //              let nearestBus = busLocationViewModel.nearestBus(from: currentLocation) else {
        //            return
        //        }
        //
        //        // 다음 정류장 ID가 변경된 경우에만 UI 업데이트 (중복 업데이트 방지)
        //        if nearestBus.nextStId != previousBusStId {
        //            // 이전 ID 저장
        //            previousBusStId = nearestBus.nextStId
        //
        //            // 메인 스레드에서 UI 업데이트 실행
        //            DispatchQueue.main.async {
        //                // BusStopSeoulViewModel의 currentBusLocationMapping 메소드 호출하여 UI 업데이트
        //                if !nearestBus.nextStId.isEmpty {
        //                    busStopSeoulViewModel.currentBusLocationMapping(nextStId: nearestBus.nextStId)
        //                    // 현재정류장과 도착정류장이 같으면
        //                    if let destBusIndex = busStopSeoulViewModel.currentDestinationIndex,
        //                       busStopSeoulViewModel.busStations.indices.contains(destBusIndex) {
        //                        if nearestBus.nextStId == busStopSeoulViewModel.busStations[destBusIndex].station {
        //                            // TODO: 알람 종료뷰 띄워주기 위한 트리거 변환
        ////                            busStopSeoulViewModel.navigateToAlarmEndView = true
        //                        }
        //                    }
        //                }
        ////            }
        ////        }
    }
}
