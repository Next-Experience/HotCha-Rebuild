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
    @StateObject private var sheetManager = AlarmSettingModalSheetManager()
    let bus: Bus_info_seoul // 선택된 버스 정보
    let cityCode: Int
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    @StateObject private var busStopSeoulViewModel = BusStopSeoulViewModel()
    
    @State private var liveActivityStated = false // Live Activity 중복 실행 방지
    
    var body: some View {
        NavigationStack {
            BusStopListView(bus: bus, cityCode: 1)
                .onAppear {
                    sheetManager.showAlarmSearchSheet1 = true // 뷰가 나타날 때 자동으로 showAlarmSearchSheet1 sheet 열기
                    
                    if !liveActivityStated {
                        startLiveActivity()
                        liveActivityStated = true
                    }
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
        .navigationBarBackButtonHidden(true) // 기본 뒤로가기 버튼 숨기기
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
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
    
    private func startLiveActivity() {
        let attributes = BeforeBusStopAttributes(name: bus.busRouteNm)
        
        let contentState = BeforeBusStopAttributes.ContentState(
            busNumber: bus.busRouteAbrv,
            busRouteType: bus.routeType,
            busStopName: bus.stStationNm,
            remainingStops: 5, // 남은 정류장 수
            currentStopName: bus.stStationNm,
            destinationStopName: bus.edStationNm
        )
        
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        do {
            _ = try Activity<BeforeBusStopAttributes>.request(attributes: attributes, content: content, pushType: nil)
            print("Live Activity 성공적으로 시작 : \(bus.busRouteNm)")
        } catch {
            print("Live Activity 시작 실패 : \(error.localizedDescription)")
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
