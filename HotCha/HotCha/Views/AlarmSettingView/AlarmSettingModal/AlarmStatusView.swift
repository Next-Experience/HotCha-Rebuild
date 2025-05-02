//
//  AlarmStatusView.swift
//  HotCha
//
//  Created by Yeji Seo on 3/10/25.
//

import SwiftUI

struct AlarmStatusView: View {
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    // Status 뷰에서만 backgound에서 크기를 인식해서 모달 상태를 변경하도록 함
    @State private var isViewActive = false
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let isSmall = height < 150
            let isMedium = height >= 250 && height < 600
            let isLarge = height >= 600
            
            
            VStack(alignment: .leading, spacing: 0) {
                
                if isMedium || isLarge {
                    BusStopInfoSection()
                }
                
                // 중간 이상 크기일 때만 표시
                if isMedium || isLarge {
                    BusStopDestinationSection()
                        .environmentObject(busStopSeoulViewModel)
                }
                
                if isLarge {
                    AlertSettingSection()
                }
                Spacer()
                Divider()
                AlertStopsSection()
                    .environmentObject(busLocationViewModel)
                    .environmentObject(busStopSeoulViewModel)
            }
            .font(.pretendard(.semibold, size: 16))
            .onAppear {
                isViewActive = true
                updateModalState(height: height)
            }
            // 뷰가 사라질 때 비활성 상태로 설정
            .onDisappear {
                isViewActive = false
            }
            // 사이즈 변경 추적
            .background(
                HeightObserver(height: height, isActive: $isViewActive) { newHeight in
                    updateModalState(height: newHeight)
                }
            )
        }
    }
    
    // 모달 상태 업데이트 함수
    private func updateModalState(height: CGFloat) {
        // 이 뷰가 활성화된 상태일 때만 모달 상태 업데이트
        guard isViewActive else { return }
        
        if height < 150 {
            modalStateViewModel.modalState = .alertStopsSmall
        } else if height >= 250 && height < 600 {
            modalStateViewModel.modalState = .alertStopsMedium
        } else if height >= 600 {
            modalStateViewModel.modalState = .alertStopsLarge
        }
    }
}

// 높이 변경을 관찰하는 헬퍼 뷰
struct HeightObserver: View {
    let height: CGFloat
    @Binding var isActive: Bool
    let onChange: (CGFloat) -> Void
    
    var body: some View {
        Color.clear
            .frame(height: 0)
            .onChange(of: height) { newHeight in
                // 활성 상태일 때만 콜백 실행
                if isActive {
                    onChange(newHeight)
                }
            }
    }
}

struct BusStopDestinationSection: View {
    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager // modal sheet를 여닫음
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        VStack(spacing: 0){
            // 첫 번째 정류장
            Button(action: {
                modalStateViewModel.modalState = .alarmWait
                sheetManager.showAlarmInfoSheet2 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    sheetManager.showAlarmSearchSheet1 = true
                    busStopSeoulViewModel.switchToDestinationMode()
                }
            }){
                HStack {
                    Image("map_pin")
                        .frame(width: 16, height: 16)
                        .foregroundColor(.mainpurple)
                        .padding(.leading,16)
                    if let index = busStopSeoulViewModel.currentDestinationIndex {
                        Text(busStopSeoulViewModel.busStations[index].stationNm)
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(.gray900)
                            .padding(.vertical, 16)
                            .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
                .background(.gray150)
            }
            
            Divider()
            
            // 두 번째 정류장
            HStack {
                Image(systemName: "bell")
                    .frame(width: 16, height: 16)
                    .foregroundColor(.mainpurple)
                    .padding(.leading, 16)
                
                if let index = busStopSeoulViewModel.currentAlarmIndex {
                    Text(busStopSeoulViewModel.busStations[index].stationNm)
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(.gray900)
                        .padding(.vertical, 16)
                        .padding(.leading, 8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray300)
                    .padding(.trailing, 16)
            }
            .background(.gray150)
        }
        .cornerRadius(8)
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
    }
    
}

struct AlertSettingSection: View {
    @AppStorage("soundToggle") private var soundToggle: Bool = true
    @AppStorage("vibrationToggle") private var vibrationToggle: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15){
            Text("알림 설정")
            HStack(spacing: 8){
                Image("word")
                    .frame(width: 20, height: 20)
                Toggle("소리", isOn: $soundToggle)
                    .toggleStyle(SwitchToggleStyle(tint: Color.mainpurple))
            }
            HStack{
                Image("word")
                    .frame(width: 20, height: 20)
                Toggle("진동", isOn: $vibrationToggle)
                    .toggleStyle(SwitchToggleStyle(tint: .mainpurple))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .font(.pretendard(.semibold, size: 16))
    }
}


struct AlertStopsSection: View {
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack(alignment: .bottom){
            Text("\(busStopSeoulViewModel.distanceToDestinationStop() ?? 0)정거장 전")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            Spacer()
            Button(action: {
                busLocationViewModel.stopFetching()
                dismiss()
            }){
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray150)
                    .frame(width: 92, height: 36)
                    .overlay(
                        Text("안내 종료")
                            .foregroundStyle(.mainpurple)
                            .font(.pretendard(.medium, size: 16))
                    )
            }
            
        }
        .padding(EdgeInsets(top: 21, leading: 20, bottom: 48, trailing: 20))
    }
}


struct BusStopInfoSection: View {
    @State var isFavorite: Bool = false
    //    @State var startStationName: String? = "시작역 없음"
    //    @State var endStationName: String? = "도착역 없음"
    //    @State var busNumber: String? = "버스번호 없음"
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        VStack(alignment:. leading, spacing: 12){
            HStack (alignment: .center){
                Text(modalStateViewModel.bus?.busRouteNm ?? "버스번호 없음")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(.skybluec)
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .background(RoundedRectangle(cornerRadius: 4).fill(.skybluec.opacity(0.2)))
                Spacer()
                if modalStateViewModel.modalState == .alertStopsLarge || modalStateViewModel.modalState == .alertStopsMedium  {
                    Button(action: {
                        isFavorite.toggle()
                    }) {
                        Image(isFavorite ? "star_fill" : "star_empty")
                    }
                }
            }
            HStack(spacing: 6){
                Text(modalStateViewModel.bus?.stStationNm ?? "시작역 없음")
                Text("↔")
                Text(modalStateViewModel.bus?.edStationNm ?? "도착역 없음")
            }
            .font(.pretendard(.semibold, size: 18))
            .foregroundStyle(.gray600)
            .padding(.bottom, 4)
        }
        .padding(EdgeInsets(top: 26, leading: 20, bottom: 16, trailing: 20))
    }
}


//
//#Preview {
//    AlarmSettingView()
//}
