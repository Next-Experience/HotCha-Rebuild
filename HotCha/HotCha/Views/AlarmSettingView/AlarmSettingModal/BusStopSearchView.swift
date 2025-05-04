//
//  BusStopSearchView.swift
//  HotCha
//
//  Created by Yeji Seo on 3/6/25.
//
import SwiftUI
import ActivityKit

struct BusStopSearchView: View {
    @State var text: String = ""
    @State var busStopSearchText:String = ""
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    
    var body: some View {
        VStack(alignment:. leading, spacing: 0){
            VStack(alignment:. leading, spacing: 0){
                BusStopInfoSection(isBookmark: .constant(false))
                BusStopSearchTextField(busStopSearchText: $busStopSearchText, isBookmark: .constant(false))
                    .environmentObject(modalStateViewModel)
                    .environmentObject(busStopSeoulViewModel).environmentObject(busLocationViewModel)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                
            }
            
            Divider()
            
            modalStateViewModel.modalState.alarmSettingSearchBottomView
        }
    }
}
struct BusStopSearchforBookmarkView: View {
    @State var text: String = ""
    @State var busStopSearchText:String = ""
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    @Binding var isBookmark: Bool
    
    var body: some View {
        VStack(alignment:. leading, spacing: 0){
            VStack(alignment:. leading, spacing: 0){
                if !isBookmark {
                    BusStopInfoSection(isBookmark: $isBookmark)
                    BusStopSearchTextField(busStopSearchText: $busStopSearchText, isBookmark: $isBookmark)
                        .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(busLocationViewModel)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                } else {
                    BusStopInfoSection(isBookmark: $isBookmark)
                    BusStopSearchTextField(busStopSearchText: $busStopSearchText, isBookmark: $isBookmark)
                        .environmentObject(modalStateViewModel)
                        .environmentObject(busStopSeoulViewModel)
                        .environmentObject(busLocationViewModel)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                }
            }
            if !isBookmark {
                Divider()
            } else {}
        }
    }
}

#Preview {
    BusStopSearchView()
        .environmentObject(AlarmModalViewModel())
        .environmentObject(BusStopSeoulViewModel())
        .environmentObject(BusLocationViewModel())
}



struct AlarmSearchScrollButtonSection: View {
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        ZStack(alignment: .center){
            HStack() {
                // 필터링된 항목 인덱스 표시
                if busStopSeoulViewModel.filteredStations.isEmpty {
                    Text("0/0")
                        .foregroundStyle(.gray300)
                } else {
                    Text("\(busStopSeoulViewModel.currentFilteredIndex + 1)/\(busStopSeoulViewModel.filteredStations.count)")
                        .foregroundStyle(.gray300)
                }
                Spacer()
                Button(action:{
                    modalStateViewModel.modalState = .alarmWait
                    busStopSeoulViewModel.searchText = ""
                    busStopSeoulViewModel.searchTextFieldfocused = false
                }){
                    Text("정류장 선택")
                        .foregroundStyle(.mainpurple)
                }
            }
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 41, trailing: 20))
            
            HStack {
                Button(action: {
                    // 위 버튼: 이전 필터링된 항목으로 이동
                    busStopSeoulViewModel.moveToPreviousFilteredStation()
                    hideKeyboard()
                }) {
                    Ellipse()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(busStopSeoulViewModel.isFirstFilteredIndex == true ? .gray200 : .mainpurple)
                        .overlay(
                            Image("bt_up")
                        )
                }
                .disabled(busStopSeoulViewModel.filteredStations.isEmpty)
                .padding(.trailing, 20)
                
                Button(action: {
                    // 아래 버튼: 다음 필터링된 항목으로 이동
                    busStopSeoulViewModel.moveToNextFilteredStation()
                    hideKeyboard()
                }) {
                    Ellipse()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(busStopSeoulViewModel.isLastFilteredIndex == true ? .gray200 : .mainpurple)
                        .overlay(
                            Image("bt_down")
                        )
                }
                .disabled(busStopSeoulViewModel.filteredStations.isEmpty)
            }
        }
        .padding(EdgeInsets(top: 15, leading: 0, bottom: 37, trailing: 0))
    }
}



struct MainPurpleAlarmButton: View {
    @State var isInfoFilled: Bool
    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager // modal sheet를 여닫음
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    
    // LiveActivity 중복 실행 방지
    @State private var liveActivityStarted = false
    // 현재 진행중인 알람이 있는지 여부
    @AppStorage("isAlarmInProgress") var isAlarmInProgress: Bool = false
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Button(action: {
                if busStopSeoulViewModel.currentDestinationIndex != nil {
                    // LiveActivity 시작
                    if !liveActivityStarted {
                        startLiveActivity()
                        liveActivityStarted = true
                    }
                    
                    // 알람 정보 저장
                    saveAlarmInfo()
                    
                    // 검색 값 초기화 신호 보내기
                    NotificationCenter.default.post(name: Notification.Name("ResetSearchText"), object: nil)
                    
                    // 모달 상태 변경
                    busStopSeoulViewModel.disableAfterDestinationStation()
                    modalStateViewModel.modalState = .alertStopsMedium
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        busLocationViewModel.startFetching() // 현재 버스위치 추적 시작
                    }
                    sheetManager.showAlarmSearchSheet1 = false
                    
                    // 강제로 알람 활성화 상태 설정
                    UserDefaults.standard.set(true, forKey: "alarmActive")
                    UserDefaults.standard.synchronize() // 즉시 동기화
                    
                    print("알람 활성화 상태 설정: \(UserDefaults.standard.bool(forKey: "alarmActive"))")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        sheetManager.showAlarmInfoSheet2 = true
                        busStopSeoulViewModel.setAlarmTwoStationsBeforeDestination() // 도착정류장의 2 정류장 전에 알람 정류장으로 설정
                        busStopSeoulViewModel.switchToAlarmMode() // 알람 모드로 전환
                        
                        // MainView에 알람 상태 전달
                        NotificationCenter.default.post(
                            name: Notification.Name("AlarmStatusChanged"),
                            object: nil,
                            userInfo: ["alarmActive": true]
                        )
                    }
                }
                
                busStopSeoulViewModel.isReload = true // 알람이 시작한 상태이기 때문에, 시작한 상태로 알람에 다시 들어오면 정보를 그대로 띄워주기 위한 트리거
                
                // TODO: 앱스토리지에 알람 진행중인 상태 저장
                isAlarmInProgress = true
                
            }, label: {
                Text("알림 시작")
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
    }
    
    // 알람 정보 저장
    private func saveAlarmInfo() {
        guard let bus = modalStateViewModel.bus else { return }
        
        // 선택된 버스 정류장 정보 가져오기
        let destinationStationName = busStopSeoulViewModel.currentDestinationIndex != nil ?
            busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentDestinationIndex!].stationNm : bus.edStationNm
        
        // 남은 정류장 수 계산
        let remainingStops =  0
        
        // UserDefaults에 정보 저장
        UserDefaults.standard.set(bus.busRouteAbrv, forKey: "alarmBusNo")
        UserDefaults.standard.set(bus.routeType, forKey: "alarmBusType")
        UserDefaults.standard.set(destinationStationName, forKey: "alarmDestination")
        UserDefaults.standard.set(remainingStops, forKey: "alarmRemainingStops")
        
        // 알람 버스 ID 저장 (나중에 화면 복원에 사용)
        UserDefaults.standard.set(bus.busRouteId, forKey: "alarmBusRouteId")
        
        // 도시 코드 저장
        UserDefaults.standard.set(modalStateViewModel.cityCode, forKey: "alarmCityCode")
        
        // 즉시 동기화
        UserDefaults.standard.synchronize()
    }
    
    // LiveActivity 시작 함수
    private func startLiveActivity() {
        guard let bus = modalStateViewModel.bus else { return }
        
        let attributes = BeforeBusStopAttributes(name: bus.busRouteNm)
        
        // 선택된 버스 정류장 정보 가져오기
        let destinationStationName = busStopSeoulViewModel.currentDestinationIndex != nil ?
            busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentDestinationIndex!].stationNm : bus.edStationNm
        
        let alarmStationName = busStopSeoulViewModel.currentAlarmIndex != nil ?
            busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentAlarmIndex!].stationNm : bus.stStationNm
        
        // 남은 정류장 수 계산
        let remainingStops = 0
        
        let contentState = BeforeBusStopAttributes.ContentState(
            busNumber: bus.busRouteAbrv,
            busRouteType: bus.routeType,
            busStopName: alarmStationName,
            remainingStops: remainingStops,
            currentStopName: alarmStationName,
            destinationStopName: destinationStationName
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
