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
    
    var body: some View {
        VStack(alignment:. leading, spacing: 0){
            VStack(alignment:. leading, spacing: 0){
                BusStopInfoSection()
                BusStopSearchTextField(busStopSearchText: $busStopSearchText)
                    .environmentObject(modalStateViewModel)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                
            }
            
            Divider()
            
            modalStateViewModel.modalState.alarmSettingSearchBottomView
        }
    }
}


struct AlarmSearchScrollButtonSection: View {
    var body: some View {
        ZStack(alignment: .center){
            HStack() {
                Text("1/2")
                    .foregroundStyle(.gray300)
                Spacer()
                Text("정류장 선택")
                    .foregroundStyle(.mainpurple)
            }
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 41, trailing: 20))
            
            HStack(alignment:.center, spacing: 0){
                Ellipse()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.gray200)
                    .overlay(
                        Image("bt_up")
                    )
                    .padding(.trailing, 20)
                
                Ellipse()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.mainpurple)
                    .overlay(
                        Image("bt_down")
                    )
            }
            .padding(EdgeInsets(top: 15, leading: 0, bottom: 37, trailing: 0))
        }
    }
}


struct MainPurpleAlarmButton: View {
    @State var isInfoFilled: Bool
    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager // modal sheet를 여닫음
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Button(action: {
                modalStateViewModel.modalState = .alertStopsMedium
                // TODO: isInfoFilled가 true이면 바로 아래 코드가 실행되도록 하면됨
                sheetManager.showAlarmSearchSheet1 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    sheetManager.showAlarmInfoSheet2 = true
                }
            
            }, label: {
                Text("알림 시작")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(isInfoFilled ? .gray50 : .gray150)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(isInfoFilled ? .mainpurple : .gray200)
                            .frame(maxWidth: .infinity)
                    )
                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 36, trailing: 20))
            })

            Spacer()
        }
    }
}
