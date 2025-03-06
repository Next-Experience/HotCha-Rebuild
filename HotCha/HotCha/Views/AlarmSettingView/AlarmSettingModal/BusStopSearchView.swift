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
    var body: some View {
        VStack(alignment:. leading, spacing: 12){
            VStack(alignment:. leading, spacing: 12){
                BusStopInfoSection()
                BusStopSearchTextField(busStopSearchText: $busStopSearchText)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            AlarmSearchScrollButtonSection()
            //            MainPurpleAlarmButton()
            
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
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 37, trailing: 20))
            
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
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Text("알림 시작")
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(.gray50)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(.mainpurple)
                        .frame(maxWidth: .infinity)
                )
                .padding(EdgeInsets(top: 3, leading: 20, bottom: 36, trailing: 20))
            Spacer()
        }
    }
}
