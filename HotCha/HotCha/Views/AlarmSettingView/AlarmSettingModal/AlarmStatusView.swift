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
                    BusStopInfoSection(isBookmark: .constant(false))
                }
                
                // 중간 이상 크기일 때만 표시
                if isMedium || isLarge {
                    BusStopDestinationSection()
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(busLocationViewModel)
                }
                
                if isLarge {
                    AlertSettingSection()
                }
                Spacer()
                Divider()
                AlertStopsSection()
                    .environmentObject(busLocationViewModel)
                    .environmentObject(busStopSeoulViewModel)
                    .environmentObject(modalStateViewModel)
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
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    
    
    var body: some View {
        VStack(spacing: 0){
            // 알람 정류장
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

            }
            .background(.gray150)
            
            Divider()
            // 도착 정류장
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
                Button(action: {
                    modalStateViewModel.modalState = .alarmWait
                    sheetManager.showAlarmInfoSheet2 = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        sheetManager.showAlarmSearchSheet1 = true
                        busStopSeoulViewModel.switchToDestinationMode()
                        busLocationViewModel.stopFetching()
                    }
                }){
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray200)
                        .frame(width: 37, height: 22)
                        .overlay(
                            Text("수정")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.gray600)
                        )
                        .padding(.trailing, 16)
                }
            }
            .background(.gray150)
        }
        .cornerRadius(8)
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
    }
}



struct AlertSettingSection: View {
    @AppStorage("soundToggle") var soundToggle: Bool = true
    @AppStorage("vibrationToggle") var vibrationToggle: Bool = true
    
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

    @StateObject private var vm = NearestBusViewModel()

    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    // 도착 정류장에서 남은 버스 정류장 distance를 담은 변수
    @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."
  
    
    
    var body: some View {
        HStack(alignment: .bottom){
//            if let distanceToDestinationStop = busStopSeoulViewModel.distanceToDestinationStop() {
//                Text("\(abs(distanceToDestinationStop))")
//                    .font(.pretendard(.bold, size: 24))
//                    .foregroundStyle(.gray900)
//            }
//            Text((busStopSeoulViewModel.distanceToDestinationStop() ?? 0) >= 0 ? "정거장 전" : "정거장 후")
            Text(remainingStops)
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            Spacer()
            Button(action: {
                vm.stop()
                print(vm.isCalculating)
                busLocationViewModel.stopFetching()
                dismiss()

                // 초기 알람 설정 상태로 초기화
                modalStateViewModel.modalState = .alarmWait
                modalStateViewModel.bus = nil
                busStopSeoulViewModel.returnToRootView = true
                // 이용기록 저장 및 데이터 초기화
                busStopSeoulViewModel.leaveAlarm(modelContext: modelContext)

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
            .onAppear {
                
                if let index = busStopSeoulViewModel.currentDestinationIndex {
                    print("gggggg",busStopSeoulViewModel.busStations[index].station)
                    vm.stationIdInput = busStopSeoulViewModel.busStations[index].station
                    vm.busRouteId = busStopSeoulViewModel.busStations[index].busRouteId

                    vm.start(stationId: busStopSeoulViewModel.busStations[index].station, routeId:
                             busStopSeoulViewModel.busStations[index].busRouteId)
                    print(busStopSeoulViewModel.busStations[index].busRouteNm,":버스 이름", busStopSeoulViewModel.busStations[index].stationNm,":도착 정류장 이름" )
                }

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
    @Binding var isBookmark: Bool
    
    var body: some View {
        if isBookmark {
            VStack(alignment:. leading, spacing: 4){
            HStack (alignment: .center) {
                SearchBusUtil.CustomBusNoView(busNo: modalStateViewModel.bus?.busRouteNm ?? "버스번호 없음",
                                              routeType: modalStateViewModel.bus?.routeType ?? "", size: 20)
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
//            .padding(.bottom, 4)
        }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 16, trailing: 20))
    } else {
        VStack(alignment:. leading, spacing: 12){
        HStack (alignment: .center){
            SearchBusUtil.CustomBusNoView(busNo: modalStateViewModel.bus?.busRouteNm ?? "버스번호 없음",
                                          routeType: modalStateViewModel.bus?.routeType ?? "", size: 20)
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
}


//
//#Preview {
//    AlarmSettingView()
//}
