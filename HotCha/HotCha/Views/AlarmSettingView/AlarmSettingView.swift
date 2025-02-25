//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//
import SwiftUI

struct AlarmSettingView: View {
    @State var showSheet: Bool = true
    var body: some View {
        BusStopListView()
            .sheet(isPresented: $showSheet) {
                ModalView()
                    .interactiveDismissDisabled(true)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.99), .fraction(0.3)/*, .fraction(0.1)*/])
                    .presentationBackgroundInteraction(.enabled)
            }
    }
}

struct ModalView: View{
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray50
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                SearchButtonView()
//                AlarmStatusView()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct AlarmStatusView: View {
    var body: some View {
        VStack {
            Text("간선 1234")
            Text("청강리공영차고지 ↔ 광안역")
            Spacer()
            Divider()
            HStack (alignment: .bottom){
                Text("6정거장 전")
                    .font(.headline)
                    .foregroundStyle(.gray900)
                Spacer()
                Text("알림 종료")
                    .foregroundStyle(.mainpurple)
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 48, trailing: 20))
        }
    }
}

struct SearchButtonView: View {
    @State var text: String = ""
    @State var busStopSearchText:String = ""
    var body: some View {
        VStack(alignment:. leading, spacing: 12){
            VStack(alignment:. leading, spacing: 12){
                Text("간선 1234")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(.skybluec)
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .background(RoundedRectangle(cornerRadius: 4).fill(.skybluec.opacity(0.1)))
                
                HStack(spacing: 6){
                    Text("청강리공영차고지")
                    Text("↔")
                    Text("광안역")
                }
                .font(.pretendard(.semibold, size: 18))
                .foregroundStyle(.gray600)
                BusstopSearchTextField(busStopSearchText: $busStopSearchText)
            }
            .padding(.horizontal, 20)
            
            Divider()
            
//            AlarmSearchScrollButtonView()
            MainPurpleAlarmButton()
            
        }
    }
}

struct AlarmSearchScrollButtonView: View {
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
                .padding(EdgeInsets(top: 16, leading: 20, bottom: 36, trailing: 20))
            Spacer()
        }
    }
}


#Preview {
    AlarmSettingView()
}
