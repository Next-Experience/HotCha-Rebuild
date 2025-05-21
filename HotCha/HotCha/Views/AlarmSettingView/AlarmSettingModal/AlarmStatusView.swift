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
    @EnvironmentObject var nearestBusViewModel: NearestBusViewModel
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
                        .environmentObject(nearestBusViewModel)
                }
                
                if isLarge {
                    AlertSettingSection()
                }
                Spacer()
                Divider()
                AlertStopsSection()
                    .environmentObject(busStopSeoulViewModel)
                    .environmentObject(modalStateViewModel)
                    .environmentObject(nearestBusViewModel)
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
    @EnvironmentObject var nearestBusViewModel: NearestBusViewModel
    
    
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
                    busStopSeoulViewModel.currentAlarmIndex = nil
                    modalStateViewModel.modalState = .alarmWait
                    sheetManager.showAlarmInfoSheet2 = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        sheetManager.showAlarmSearchSheet1 = true
                        busStopSeoulViewModel.switchToDestinationMode()
                        nearestBusViewModel.stop()
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
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    
    @EnvironmentObject private var nearestBusViewModel: NearestBusViewModel
    
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(alignment: .bottom){
            Text("\(abs(Int(nearestBusViewModel.remainingStop ?? 0)))")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            Text(Int(nearestBusViewModel.remainingStop ?? 0) >= 0 ? "정류장 전" : "정류장 후")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            
            
            Spacer()
            Button(action: {
                
                print(nearestBusViewModel.isCalculating)
                // 현재 정류장 위치 찾기 종료
                nearestBusViewModel.stop()
                dismiss()
                
                // 이용기록
                let currentTime = Date()
                
                if let currentBusIndex = busStopSeoulViewModel.getDestinationStationIndex() {
                    let newUsage = Usage_history(
                        bus: busStopSeoulViewModel.bus ?? busStopSeoulViewModel.fallbackBus,
                        route_id: busStopSeoulViewModel.bus?.busRouteId ?? "아이디 없음",
                        city_code: "1",
                        destination_stop_id: busStopSeoulViewModel.busStations[currentBusIndex].station,
                        destination_stop_name: busStopSeoulViewModel.busStations[currentBusIndex].stationNm,
                        bus_no: busStopSeoulViewModel.bus?.busRouteNm ?? "번호 없음",
                        route_type: busStopSeoulViewModel.bus?.routeType ?? "타입 없음",
                        get_off_timestamp: currentTime,
                        operator_name: busStopSeoulViewModel.bus?.corpNm ?? "정보 없음",
                        operator_no: "정보 없음", // TODO: 운수사 전번 넣기
                        vehicle_no: "정보 없음" //TODO: vehicle_no 차량번호 넣기
                    )
                    print("bus Info: \(busStopSeoulViewModel.bus)")
                    print("newUsage: \(newUsage.route_id)   \(newUsage.destination_stop_id)  \(newUsage.destination_stop_name)  \(newUsage.route_type)  \(newUsage.bus_no)")
                    modelContext.insert(newUsage)
                }
                
                // 데이터 초기화
                busStopSeoulViewModel.leaveAlarm()
                
                // 초기 알람 설정 상태로 초기화
                modalStateViewModel.modalState = .alarmWait
                modalStateViewModel.bus = nil
                busStopSeoulViewModel.returnToRootView = true
                
                
                
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
                    nearestBusViewModel.stationIdInput = busStopSeoulViewModel.busStations[index].station
                    nearestBusViewModel.busRouteId = busStopSeoulViewModel.busStations[index].busRouteId
                    
                    nearestBusViewModel.start(stationId: busStopSeoulViewModel.busStations[index].station, routeId:
                                                busStopSeoulViewModel.busStations[index].busRouteId, cityCode: busStopSeoulViewModel.bus?.city_code ?? "1")
                    print(busStopSeoulViewModel.busStations[index].busRouteNm,":버스 이름", busStopSeoulViewModel.busStations[index].stationNm,":도착 정류장 이름" )
                }
                
            }
        }
        .padding(EdgeInsets(top: 21, leading: 20, bottom: 48, trailing: 20))
    }
}

import SwiftData


struct BusStopInfoSection: View {
    @State var isFavorite: Bool = false
    //    @State var startStationName: String? = "시작역 없음"
    //    @State var endStationName: String? = "도착역 없음"
    //    @State var busNumber: String? = "버스번호 없음"
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var ViewModel: NearestBusViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @Binding var isBookmark: Bool
    @Environment(\.modelContext) private var modelContext
    @Query var bookmarkdata: [Bookmarkmodel]
    @State var quickBookmark: Bool = false
    
    
    var body: some View {
        if isBookmark {
            VStack(alignment:. leading, spacing: 4){
                HStack (alignment: .center) {
                    SearchBusUtil.CustomBusNoView(busNo: modalStateViewModel.bus?.busRouteNm ?? "버스번호 없음",
                                                  routeType: modalStateViewModel.bus?.routeType ?? "", size: 20)
                    Spacer()
//                    if modalStateViewModel.modalState == .alertStopsLarge || modalStateViewModel.modalState == .alertStopsMedium  {
//                        Button(action: {
//                            isFavorite.toggle()
//                        }) {
//                            Image(isFavorite ? "star_fill" : "star_empty")
//                        }
//                    }
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
                        //                        Button(action: {
                        //                            isFavorite.toggle()
                        //                        }) {
                        //                            Image(isFavorite ? "star_fill" : "star_empty")
                        //                        }
                        
                        if let yes = modalStateViewModel.bus {
                        if let index = busStopSeoulViewModel.currentDestinationIndex {
                            if isDuplicate(id: yes.busRouteId, ggid: busStopSeoulViewModel.busStations[index].station) || quickBookmark == true {
                                Image("star_fill")
                            } else {
                                Image("star_empty")
                                    .onTapGesture {
                                        if (bookmarkdata.filter { $0.bookmark_type == 0 }.count < 4) {
                                            let newBookmark = Bookmarkmodel(
                                                bus: yes,
                                                route_id: yes.busRouteId,
                                                city_code: yes.city_code,
                                                destination_stop_id: busStopSeoulViewModel.busStations[index].station,
                                                destination_stop_name: busStopSeoulViewModel.busStations[index].stationNm,
                                                bus_no: yes.busRouteNm,
                                                route_type: yes.routeType,
                                                bookmark_label: "빠른 추가 \(yes.busRouteNm)",
                                                bookmark_type: 0
                                            )
                                            modelContext.insert(newBookmark)
                                            
                                            quickBookmark = true
                                        }
                                    }
                            }
                            }
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
    func isDuplicate(id: String, ggid: String) -> Bool {
        // 같은 ID 가진 항목 필터링
        let sameIDItems = bookmarkdata.filter { $0.route_id == id }
        // 그 중 ggid도 같은 게 있는지 확인
        return sameIDItems.contains { $0.destination_stop_id == ggid }
    }
}


//
//#Preview {
//    AlarmSettingView()
//}
