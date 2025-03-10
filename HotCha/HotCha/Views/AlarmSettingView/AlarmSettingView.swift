//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//
import SwiftUI

struct AlarmSettingView: View {
    @State var showSheet: Bool = true

    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    
    var body: some View {
        BusStopListView()
            .sheet(isPresented: $showSheet) {
                ModalView()
                    .interactiveDismissDisabled(true)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.99), .fraction(0.4), .fraction(0.32), .fraction(0.1)], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(20)
            }
    }
}

struct ModalView: View{
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
