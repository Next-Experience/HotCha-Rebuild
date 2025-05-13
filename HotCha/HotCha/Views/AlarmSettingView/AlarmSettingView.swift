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
    
    @Binding var bus: Bus_info_seoul // 선택된 버스 정보
    @Binding var cityCode: Int
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    @AppStorage("isAlarmInProgress") var isAlarmInProgress: Bool = false // 알람 실행 중 여부
    
    // 시트 구분을 위한 ID 추가
    @State private var sheetId = UUID()
    
    var body: some View {
        ZStack {
            NavigationStack {
                BusStopListView(bus: bus,
                                cityCode: 1,
                                busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel)
                // 알람 종료뷰로 이동
                .overlay {
                    if busStopSeoulViewModel.navigateToAlarmEndView {
                        // 어두운 배경
                        Rectangle()
                            .fill(Color.black.opacity(0.8))
                            .ignoresSafeArea()
                        
                        // AlarmEndView
                        AlarmEndView()
                            .environmentObject(sheetManager)
                            .environmentObject(busStopSeoulViewModel)
                            .environmentObject(modalStateViewModel)
                            .environmentObject(nearestBusViewModel)
                            .transition(.opacity) // 부드러운 전환 효과
                    }
                }
                .onAppear {
                    busStopSeoulViewModel.bus = bus
                    if busStopSeoulViewModel.isReload { // 이미 진행 중인 알람을 다시 로드할 때
                        sheetManager.showAlarmInfoSheet2 = true
                    } else {
                        sheetManager.showAlarmSearchSheet1 = true // 처음 뷰가 나타날 때 자동으로 showAlarmSearchSheet1 sheet 열기
                    }
                }
                .environmentObject(sheetManager)
                .sheet(isPresented: $sheetManager.showAlarmSearchSheet1) {
                    ScrollView {
                        SettingModalView(bus: bus, cityCode: 1, isBookmark: $isBookmark, type_name: $type_name)
                            .environmentObject(sheetManager)
                            .environmentObject(modalStateViewModel)
                            .environmentObject(busStopSeoulViewModel)
                            .environmentObject(nearestBusViewModel)
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
                        .environmentObject(nearestBusViewModel)
                        .interactiveDismissDisabled(true)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.fraction(0.4), .fraction(0.1), .fraction(0.99)], selection: $selectedDetent)
                        .presentationBackgroundInteraction(.enabled)
                        .presentationCornerRadius(20)
                }
            }
            .onAppear {
                print(bus.busRouteNm, bus.busRouteId, "아 제발 좀 떠라 왜 안뜨냐")
            }
            .onChange(of: busStopSeoulViewModel.navigateToAlarmEndView) { newValue in
                if newValue == true{
                    // 알람 종료 뷰로 이동하면 시트 모두 닫기
                    busStopSeoulViewModel.closeAllSheets(using: sheetManager)
                } else {
                    selectedDetent = .fraction(0.4)
                }
                
            }.onChange(of: busStopSeoulViewModel.returnToRootView) { newValue in
                if newValue{
                    // 안내 종료 시 뷰 닫기
                    dismiss()
                }
            }
            .navigationBarBackButtonHidden(true) // 기본 뒤로가기 버튼 숨기기
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("ResetSearchState"),
                            object: nil
                        )
                        if !busStopSeoulViewModel.isReload {
                            busStopSeoulViewModel.clearSelectedData()
                            modalStateViewModel.bus = nil
                        }
                        if isBookmark {
                            // 빌드된 데이터 초기화
                            busStopSeoulViewModel.leaveAlarm()
                            
                            // 초기 알람 설정 상태로 초기화
                            modalStateViewModel.modalState = .alarmWait
                            modalStateViewModel.bus = nil
                        }
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
}

struct SettingModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var nearestBusViewModel: NearestBusViewModel
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
                        
                        if type_name == "집" || type_name == "회사" {
                            HStack {
                                HStack {
                                    HStack{
                                        Text(type_name)
                                            .foregroundColor(.gray300)
                                        Spacer()
                                    }
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
                        } else {
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
                                bus: bus,
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
                            
                            busStopSeoulViewModel.returnToRootView = true
                            
                            // 빌드된 데이터 초기화
                            busStopSeoulViewModel.leaveAlarm()
                            
                            // 초기 알람 설정 상태로 초기화
                            modalStateViewModel.modalState = .alarmWait
                            modalStateViewModel.bus = nil
                            
                            
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
                    
                } else {
                    modalStateViewModel.modalState.alarmSettingMainView
                        .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(nearestBusViewModel)
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
}
