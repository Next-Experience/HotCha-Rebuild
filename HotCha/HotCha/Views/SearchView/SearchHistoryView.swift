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
    @State var isBookmark: Bool = false
    @State var type_name: String = ""
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager
    @State private var shouldNavigateAlarm = false  // 네비게이션 트리거
    @State private var selectedBus: Bus_info_seoul? = nil
    
    var body: some View {
        HStack {
            Text("최근 이용 기록")
                .font(.pretendard(.medium, size: 16))
                .foregroundColor(Color("gray300"))
                .padding(.top, 6)
            Spacer()
        }
        ScrollView {
            VStack {
                ForEach(Usage_history) {history in
                    SerachHistoryBlockView(history: history)
                        .onTapGesture {
                            selectedBus = history.bus
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
        .navigationDestination(isPresented: $shouldNavigateAlarm) {
            AlarmSettingView(
                bus: .constant(selectedBus ?? busStopSeoulViewModel.fallbackBus),
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


