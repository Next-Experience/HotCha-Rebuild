//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//
import SwiftUI

struct AlarmSettingView: View {
    @StateObject private var sheetManager = AlarmSettingModalSheetManager()

    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    
    var body: some View {
        BusStopListView()
            .onAppear {
                sheetManager.showAlarmSearchSheet1 = true // 뷰가 나타날 때 자동으로 showAlarmSearchSheet1 sheet 열기
                        }
            .environmentObject(sheetManager)
            .sheet(isPresented: $sheetManager.showAlarmSearchSheet1) {
                SettingModalView()
                    .environmentObject(sheetManager)
                    .interactiveDismissDisabled(true)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.32)], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(20)
            }
            .sheet(isPresented: $sheetManager.showAlarmInfoSheet2) {
                SettingModalView()
                    .environmentObject(sheetManager)
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
    @StateObject private var modalStateViewModel = AlarmModalViewModel()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray50
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                modalStateViewModel.modalState.alarmSettingMainView
                    .environmentObject(modalStateViewModel)
//                AlarmStatusView()
            
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    AlarmSettingView()
}
