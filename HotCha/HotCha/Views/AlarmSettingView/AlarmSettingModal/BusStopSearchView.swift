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
    
//    @Binding var bus: Bus_info_seoul // 선택된 버스 정보
//    @Binding var cityCode: Int
    
  
    // 현재 진행중인 알람이 있는지 여부
    @AppStorage("isAlarmInProgress") var isAlarmInProgress: Bool = false
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Button(action: {
                if busStopSeoulViewModel.currentDestinationIndex != nil {
                    
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
    

    

}
