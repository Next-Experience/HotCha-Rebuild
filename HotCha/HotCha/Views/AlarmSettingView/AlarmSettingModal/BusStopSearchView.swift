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
    
    var body: some View {
        VStack(alignment:. leading, spacing: 0){
            VStack(alignment:. leading, spacing: 0){
                BusStopInfoSection()
                BusStopSearchTextField(busStopSearchText: $busStopSearchText)
                    .environmentObject(modalStateViewModel)
                    .environmentObject(busStopSeoulViewModel)
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
                    busStopSeoulViewModel.storeDestinationStation()
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
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Button(action: {
                if busStopSeoulViewModel.currentDestinationIndex != nil {
                    modalStateViewModel.modalState = .alertStopsMedium
                    sheetManager.showAlarmSearchSheet1 = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        sheetManager.showAlarmInfoSheet2 = true
                    }
                }
                
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
