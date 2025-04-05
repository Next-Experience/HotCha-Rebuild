//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//
import SwiftUI

struct AlarmSettingView: View {
    @StateObject private var sheetManager = AlarmSettingModalSheetManager()
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    @StateObject private var busStopSeoulViewModel = BusStopSeoulViewModel()

    var body: some View {
        BusStopListView(bus: bus, cityCode: 1)
            .onAppear {
                sheetManager.showAlarmSearchSheet1 = true // 뷰가 나타날 때 자동으로 showAlarmSearchSheet1 sheet 열기
            }
            .environmentObject(sheetManager)
            .environmentObject(busStopSeoulViewModel)
            .sheet(isPresented: $sheetManager.showAlarmSearchSheet1) {
                ScrollView {
                    SettingModalView(bus: bus, cityCode: 1)
                        .environmentObject(sheetManager)
                        .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .interactiveDismissDisabled(true)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.fraction(0.1),.fraction(0.32)], selection: $selectedDetent)
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
                    .interactiveDismissDisabled(true)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.99), .fraction(0.4), .fraction(0.1)], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(20)
            }
    }
}

struct SettingModalView: View{
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
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
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            modalStateViewModel.bus = bus
            modalStateViewModel.cityCode = cityCode
        }
    }
}

//#Preview {
//    AlarmSettingView(bus: "109000006", cityCode: 1)
//}
