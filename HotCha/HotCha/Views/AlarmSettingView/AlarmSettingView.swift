//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//

import SwiftUI
import ActivityKit
import SwiftData

struct AlarmSettingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var sheetManager = AlarmSettingModalSheetManager()
    @Binding var bus: Bus_info_seoul // 선택된 버스 정보
    @Binding var cityCode: Int
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    @StateObject private var busStopSeoulViewModel =  BusStopSeoulViewModel() 
    @StateObject private var busLocationViewModel =  BusLocationViewModel()
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    
    @State private var liveActivityStarted = false // Live Activity 중복 실행 방지
    
    var body: some View {
        NavigationStack {
            BusStopListView(bus: bus, cityCode: 1)
                .onAppear {
                    if busStopSeoulViewModel.isReload { // 이미 진행 중인 알람을 다시 로드할 때
                        sheetManager.showAlarmInfoSheet2 = true
                    } else {
                        sheetManager.showAlarmSearchSheet1 = true // 처음 뷰가 나타날 때 자동으로 showAlarmSearchSheet1 sheet 열기
                    }
                    
                }
                .environmentObject(sheetManager)
                .environmentObject(busStopSeoulViewModel)
                .environmentObject(busLocationViewModel)
                .sheet(isPresented: $sheetManager.showAlarmSearchSheet1) {
                    ScrollView {
                        SettingModalView(bus: bus, cityCode: 1, isBookmark: $isBookmark, type_name: $type_name)
                            .environmentObject(sheetManager)
                            .environmentObject(modalStateViewModel)
                            .environmentObject(busStopSeoulViewModel)
                            .environmentObject(busLocationViewModel)
                            .interactiveDismissDisabled(true)
                            .presentationDragIndicator(.visible)
                            .presentationDetents([.fraction(0.32)], selection: $selectedDetent)
                            .presentationBackgroundInteraction(.enabled)
                            .presentationCornerRadius(20)
                            .presentationContentInteraction(.resizes)
                    }
                    .scrollDisabled(true)
                }
                .sheet(isPresented: $sheetManager.showAlarmInfoSheet2) {
                    SettingModalView(bus: bus, cityCode: 1, isBookmark: $isBookmark, type_name: $type_name)
                        .environmentObject(sheetManager)
                        .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(busLocationViewModel)
                        .interactiveDismissDisabled(true)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.fraction(0.99), .fraction(0.4), .fraction(0.1)], selection: $selectedDetent)
                        .presentationBackgroundInteraction(.enabled)
                        .presentationCornerRadius(20)
                }
        }
        .onAppear {
            print(bus.busRouteNm, bus.busRouteId, "아 제발 좀 떠라 왜 안뜨냐")
        }
        // 알람 종료뷰로 이동
        .navigationDestination(isPresented: $busStopSeoulViewModel.navigateToAlarmEndView) {
            AlarmEndView()
                .environmentObject(sheetManager)
                .environmentObject(busLocationViewModel)
                .environmentObject(busStopSeoulViewModel)
        }
        .onChange(of: busStopSeoulViewModel.navigateToAlarmEndView) { newValue in
            if newValue {
                // 알람 종료 뷰로 이동하면 시트 모두 닫기
                busStopSeoulViewModel.closeAllSheets(using: sheetManager)
            }
        }
//        .fullScreenCover(isPresented: $busStopSeoulViewModel.navigateToAlarmEndView) {
//            AlarmEndView()
//        }
        .navigationBarBackButtonHidden(true) // 기본 뒤로가기 버튼 숨기기
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    NotificationCenter.default.post(
                        name: Notification.Name("ResetSearchState"),
                        object: nil
                    )
                    // 화면 닫기
                    dismiss()
//                    busLocationViewModel.stopFetching()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.gray900, for: .navigationBar) // 배경색 설정
        .toolbarBackground(.visible, for: .navigationBar)   // 항상 보이게
    }
}

struct SettingModalView: View{
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    
    
//    @State private var routeID: String = ""
////    @State private var cityCode: String = ""
//    @State private var destinationStopID: String = ""
//    @State private var destinationStopName: String = ""
//    @State private var busNo: String = ""
//    @State private var routeType: String = ""
    @State private var bookmarkLabel: String = ""
    @State private var bookmarktype: Int = 0
    
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray50
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                if isBookmark {
                        // 예시: 즐겨찾기 저장용 뷰
//                        BookmarkSaveView(bus: bus)
//                            .environmentObject(modalStateViewModel)
//                            .environmentObject(busStopSeoulViewModel)
//                            .environmentObject(busLocationViewModel)
                    VStack(spacing: 0){
                        BusStopSearchforBookmarkView(isBookmark: $isBookmark)
                        if type_name != "집" || type_name != "회사" {
                            HStack {
                                HStack {
                            TextField("", text: $bookmarkLabel, prompt:
                                      Text("즐겨찾기 이름을 설정해보세요.")
                                .foregroundColor(.gray300)
                                      
                            )
                            .font(.pretendard(.medium, size: 16))
                            .foregroundStyle(.gray900)
                            .accentColor(.gray900)
                            
                                }
                                .padding(16)
                            }
                            .frame(height: 52)
                            .background(.gray150)
                            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
                            .padding(.horizontal,20)
                        }
                        Button(action: {
                            
                            if type_name == "집" {
                                bookmarkLabel = "집"
                                bookmarktype = 1
                            } else if type_name == "회사" {
                                bookmarkLabel = "회사"
                                bookmarktype = 2
                            } else {
                                bookmarktype = 0
                            }
                            // 선택된 버스 정류장 정보 가져오기
                            let destinationStationName = busStopSeoulViewModel.currentDestinationIndex != nil ?
                                busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentDestinationIndex!].stationNm : bus.edStationNm
                            
                            let destinationStationid = busStopSeoulViewModel.currentDestinationIndex != nil ?
                            busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentDestinationIndex!].station : bus.edStationNm

                            let newBookmark = Bookmarkmodel(
                                route_id: bus.busRouteId,
                                city_code: String(cityCode),
                                destination_stop_id: destinationStationid,
                                destination_stop_name: destinationStationName,
                                bus_no: bus.busRouteNm,
                                route_type: bus.routeType,
                                bookmark_label: bookmarkLabel,
                                bookmark_type: bookmarktype
                            )
                            modelContext.insert(newBookmark)
                            dismiss()
                            
                        }, label: {
                            Text("즐겨찾기 저장")
                                .font(.pretendard(.semibold, size: 20))
                                .foregroundStyle(busStopSeoulViewModel.currentDestinationIndex != nil ? .gray50 : .gray150)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(busStopSeoulViewModel.currentDestinationIndex != nil ? .mainpurple : .gray200)
                                        .frame(maxWidth: .infinity)
                                )
                                .padding(EdgeInsets(top: 16, leading: 20, bottom: 36, trailing: 20))
                        })
                        
                        Spacer()
                    }
                    .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(busLocationViewModel)
                    
                    } else {
                        modalStateViewModel.modalState.alarmSettingMainView
                            .environmentObject(modalStateViewModel)
                            .environmentObject(busStopSeoulViewModel)
                            .environmentObject(busLocationViewModel)
                    }
                
                
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            modalStateViewModel.bus = bus
            modalStateViewModel.cityCode = cityCode
            print("버스 정보다 \(bus)")
        }
    }
}
#Preview {
    SettingModalView(
        bus: Bus_info_seoul(
            busRouteAbrv: "130",
            busRouteId: "109000006",
            busRouteNm: "130번",
            corpNm: "서울버스운수(주)",
            stStationNm: "강남역",
            edStationNm: "서울역",
            firstBusTm: "0430",
            firstLowTm: "",
            lastBusTm: "2330",
            lastBusYn: "Y",
            lastLowTm: "",
            length: "24.6",
            routeType: "3", // 예: 간선
            term: "12"
        ),
        cityCode: 1, isBookmark: .constant(true), type_name: .constant("집")
    )
    .environmentObject(AlarmModalViewModel())
    .environmentObject(BusStopSeoulViewModel())
    .environmentObject(BusLocationViewModel())
}
