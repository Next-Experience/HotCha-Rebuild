//
//  SearchHistoryView.swift
//  HotCha
//
//  Created by 문재윤 on 2/28/25.
//

import SwiftUI
import SwiftData

struct SearchHistoryView: View {
    @Environment(\.modelContext) private var modelContex
    @Query var Usage_history: [Usage_history]
    @Binding var isBookmark: Bool
    @State var type_name: String = ""
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager
    @State private var shouldNavigateAlarm = false  // 네비게이션 트리거
    @State private var selectedBus: Bus_info_seoul? = nil
    
    func formatBusRoute(_ route: Bus_info_seoul) -> some View {
        return VStack(spacing: 0) {
            // 각 버스 항목
            HStack {
                // 버스 번호 및 타입 블록
                SearchBusUtil.CustomBusNoView(busNo: route.busRouteNm, routeType: route.routeType)
                
                // 버스 타입 필터링
                BusTypeLabelView(busNo: route.busRouteAbrv, routeType: route.routeType)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // 출발지-도착지 정보
            HStack {
                Text("\(route.stStationNm) ↔︎ \(route.edStationNm)")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray900"))
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom)
            
            Rectangle()
                .foregroundStyle(Color("gray100"))
                .frame(height: 1)
            
        }
        .contentShape(Rectangle())
    }
    
    var body: some View {
        HStack {
            Text("최근 이용 기록")
                .font(.pretendard(.medium, size: 16))
                .foregroundColor(Color("gray300"))
                .padding(.top, 6)
            Spacer()
        }
        ScrollView {
            if isBookmark {
                VStack {
                    ForEach(Usage_history) {history in
                        NavigationLink(destination: AlarmSettingView(bus: Bus_info_seoul(from:history.bus), cityCode: .constant(1), isBookmark: $isBookmark, type_name: $type_name, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)) {
                            formatBusRoute(Bus_info_seoul(from:history.bus))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            // 이 부분에서 dismiss 호출
//                            searchActivate = false
                        })                    }
                }
            } else {
                VStack {
                    ForEach(Usage_history) {history in
                        SerachHistoryBlockView(history: history)
                            .onTapGesture {
                                selectedBus = Bus_info_seoul(from:history.bus)
                                // 알람 시작
                                busStopSeoulViewModel.shortcutDestinationId = history.destination_stop_id
                                busStopSeoulViewModel.isReload = true
                                modalStateViewModel.modalState = .alertStopsMedium
                                busStopSeoulViewModel.shortcutExecute = true // 알람 실행에 필요한 데이터를 로드하기 위한  트리거
                                shouldNavigateAlarm = true  // AlarmSettingView 네비게이션 트리거
                                print("history usage to start: \(history.destination_stop_id) \(history.bus) ")
                            }
                    }
                }

            }
        }
        .navigationDestination(isPresented: $shouldNavigateAlarm) {
            AlarmSettingView(
                bus: selectedBus ?? busStopSeoulViewModel.fallbackBus,
                cityCode: .constant(1),
                isBookmark: $isBookmark,
                type_name: $type_name,
                modalStateViewModel: modalStateViewModel,
                busStopSeoulViewModel: busStopSeoulViewModel,
                nearestBusViewModel: nearestBusViewModel,
                sheetManager: sheetManager
            )
        }
        .onAppear {
            busStopSeoulViewModel.returnToRootView = false
            shouldNavigateAlarm = false
        }
    }
    
}


