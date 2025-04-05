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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0){
                    ForEach(busStopSeoulViewModel.busStations, id: \.seq) { busStop in
                        ZStack(alignment: .bottom) {
                            Divider()
                                .background(.gray100.opacity(0.15))
                            
                            BusStopElement(stopCase: busStop.busStopCase, busStop: busStop)
                                .environmentObject(busStopSeoulViewModel)
                                .id(busStop.id)
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
            // 현재 필터링된 정류장 ID가 변경될 때마다 스크롤 위치 업데이트
            .onChange(of: busStopSeoulViewModel.currentFilteredStationID) { newID in
                if let id = newID {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}

//#Preview {
//    AlarmSettingView()
//}
