//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State var bus: Bus_info_seoul = Bus_info_seoul(
        busRouteAbrv: "0",
        busRouteId: "0",
        busRouteNm: "0",
        corpNm: "0",
        stStationNm: "0",
        edStationNm: "0",
        firstBusTm: "0",
        firstLowTm: "0",
        lastBusTm: "0",
        lastBusYn: "0",
        lastLowTm: "",
        length: "0",
        routeType: "0", // 예: 간선
        term: "0",
        city_code: "1"
    )// 선택된 버스 정보
    @State var cityCode: Int = 1
    @State var isEditMode: Bool = false
    @State var searchActivate: Bool = false
    @State var textfiledValue: String = ""
    @Binding var isSwipeDisabled : Bool
    
    // 알람 활성화 상태
    @State private var alarmActive: Bool = false
    
    // 알람 정보 저장
    @State private var alarmBusNo: String = ""
    @State private var alarmBusType: String = ""
    @State private var alarmDestination: String = ""
    @State private var alarmRemainingStops: Int = 0
    
    // 알람 설정 화면 복원을 위한 정보
    @State private var savedBus: Bus_info_seoul? = nil
    @State private var savedCityCode: Int = 1
    @State private var shouldNavigateToAlarmView: Bool = false
    
    //swift data에 저장유무
    @AppStorage("Bus_info_seoul_True") var Bus_info_seoul_True: Bool = false
    
    // 현재 진행중인 알람이 있는지 여부
//    @AppStorage("isAlarmInProgress") var isAlarmInProgress: Bool = false
    // 도착 정류장에서 남은 버스 정류장 distance를 담은 변수
    @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."

    // 앱 시작 여부 플래그
    @State private var isAppStart = true
    
    @StateObject private var viewModel = BusRouteViewModel()
    @Environment(\.modelContext) private var modelContext

    @StateObject private var sheetManager = AlarmSettingModalSheetManager()
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    @StateObject private var busStopSeoulViewModel =  BusStopSeoulViewModel()
    @StateObject private var nearestBusViewModel =  NearestBusViewModel()
    
    @State var isBookmark: Bool = false
    @State var type_name: String = "0"
    
    var body: some View {
        // 메인뷰 전체
        VStack(spacing: 12) {

//            if isAlarmInProgress != false {
////            if busStopSeoulViewModel.bus != nil {
//                NavigationLink(destination: AlarmSettingView(bus: .constant(modalStateViewModel.bus ?? bus), cityCode: .constant(1), isBookmark: $isBookmark, type_name: $type_name, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)) {
//                    DoAlarmView(bus: .constant(modalStateViewModel.bus ?? bus), cityCode: .constant(1))
//                        .environmentObject(busStopSeoulViewModel)
//                        .environmentObject(modalStateViewModel)
//                        .padding(.bottom, 12)
//                }
//            } else {
                
         // '버스번호를 알려주세요' 텍스트 필드
         MainTextfiled(isEditMode: $isEditMode, textfiledValue: $textfiledValue, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name)
         .onAppear {
             print(bus.busRouteId, bus.busRouteNm)
         }

//            }
//            if let index = busStopSeoulViewModel.currentDestinationIndex {
//                Text(busStopSeoulViewModel.busStations[index].stationNm)
//                    .font(.pretendard(.semibold, size: 16))
//                    .foregroundStyle(.gray900)
//                    .padding(.vertical, 16)
//                    .padding(.leading, 8)
//            }
//                           


            
            
            if searchActivate {
                // 서치뷰 전환
                SearchView(textfiledValue: $textfiledValue, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)
            } else {
                // 즐겨찾기 항목들
                BookmarkView(bus: $bus, cityCode: $cityCode,isEditMode: $isEditMode, alarmActive: alarmActive, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)
                    .padding(.top, 12)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("gray50"))
        .onAppear{
            if !Bus_info_seoul_True {
                viewModel.fetchBusRoutes(searchStr: "")
                saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
                Bus_info_seoul_True = true
            }
            busStopSeoulViewModel.returnToRootView = false
        }
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
