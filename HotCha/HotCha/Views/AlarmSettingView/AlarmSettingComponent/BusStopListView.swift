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
    @State var busStopList: [BusStop] = [] // 버스의 노선에 있는 모든 정류장 리스트
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0){
                ForEach(busStopSeoulViewModel.busStations, id: \.seq) { busStop in
                    ZStack(alignment: .bottom) {
                        Divider()
                            .background(.gray100.opacity(0.15))
                        
                        BusStopElement(stopCase: busStop.busStopCase, busStop: busStop)
                            .environmentObject(busStopSeoulViewModel)
                    }
                }
            }
            .padding(0)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 250)
            }
        }
        .ignoresSafeArea(.all)
        .background(.gray900)
        .onAppear() {
            busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId)
        }
    
    }
}

//#Preview {
//    AlarmSettingView()
//}
