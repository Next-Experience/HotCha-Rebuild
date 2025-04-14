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
        // item drag를 커스텀 한 UIKit 테이블 뷰 사용
        DraggableBusStopList(
            busStops: busStopSeoulViewModel.busStations,
            onArrivalStationChanged: { index in
                busStopSeoulViewModel.selectDestinationStataion(destIndex: index)
            }
        )
        .ignoresSafeArea()
        .background(Color.gray900)
        .onAppear {
            busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId)
        }
    }
}
