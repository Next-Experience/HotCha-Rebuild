//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//

import SwiftUI
import ActivityKit

struct AlarmSettingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var sheetManager = AlarmSettingModalSheetManager()
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    @StateObject private var busStopSeoulViewModel =  BusStopSeoulViewModel()
    @StateObject private var busLocationViewModel =  BusLocationViewModel()
    
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
                    
                    // 버스 정보를 UserDefaults에 저장 (알람 설정 여부와 상관없이 항상 최신 정보 저장)
                    UserDefaults.standard.set(bus.busRouteId, forKey: "alarmBusRouteId")
                    UserDefaults.standard.set(cityCode, forKey: "alarmCityCode")
                }
                .environmentObject(sheetManager)
                .environmentObject(busStopSeoulViewModel)
                .environmentObject(busLocationViewModel)
                .sheet(isPresented: $sheetManager.showAlarmSearchSheet1) {
                    ScrollView {
                        SettingModalView(bus: bus, cityCode: 1)
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
                    SettingModalView(bus: bus, cityCode: 1)
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
                    // 디버깅: 알람 상태 확인 및 출력
                    let isAlarmActive = UserDefaults.standard.bool(forKey: "alarmActive")
                    
                    // 알람 변경 알림 발송 (화면 닫기 전)
                    NotificationCenter.default.post(
                        name: Notification.Name("AlarmStatusChanged"),
                        object: nil,
                        userInfo: ["alarmActive": isAlarmActive]
                    )
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("ResetSearchState"),
                        object: nil
                    )
                    
                    // 화면 닫기
                    dismiss()
                    busLocationViewModel.stopFetching()
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
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray50
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                modalStateViewModel.modalState.alarmSettingMainView
                    .environmentObject(modalStateViewModel)
                    .environmentObject(busStopSeoulViewModel)
                    .environmentObject(busLocationViewModel)
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
