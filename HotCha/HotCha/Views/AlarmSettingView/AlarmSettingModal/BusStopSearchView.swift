//
//  BusStopSearchView.swift
//  HotCha
//
//  Created by Yeji Seo on 3/6/25.
//
import SwiftUI

struct BusStopSearchView: View {
    @State var text: String = ""
    @State var busStopSearchText:String = ""
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    
    var body: some View {
        VStack(alignment:. leading, spacing: 0){
            VStack(alignment:. leading, spacing: 0){
                BusStopInfoSection()
                BusStopSearchTextField(busStopSearchText: $busStopSearchText)
                    .environmentObject(modalStateViewModel)
                    .environmentObject(busStopSeoulViewModel).environmentObject(busLocationViewModel)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                
            }
            
            Divider()
            
            modalStateViewModel.modalState.alarmSettingSearchBottomView
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
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Button(action: {
                if busStopSeoulViewModel.currentDestinationIndex != nil {
                    busLocationViewModel.startFetching() // 현재 버스위치 추적 시작
                    busStopSeoulViewModel.disableAfterDestinationStation()
                    modalStateViewModel.modalState = .alertStopsMedium
                    sheetManager.showAlarmSearchSheet1 = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        sheetManager.showAlarmInfoSheet2 = true
                        busStopSeoulViewModel.setAlarmTwoStationsBeforeDestination() // 도착정류장의 2 정류장 전에 알람 정류장으로 설정
                        busStopSeoulViewModel.switchToAlarmMode() // 알람 모드로 전환
                    }
                }
                
                busStopSeoulViewModel.isReload = true // 알람이 시작한 상태이기 때문에, 시작한 상태로 알람에 다시 들어오면 정보를 그대로 띄워주기 위한 트리거
                
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
