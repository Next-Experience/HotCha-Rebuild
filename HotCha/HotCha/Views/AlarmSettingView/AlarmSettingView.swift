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
                    .presentationDetents([.fraction(0.99), .fraction(0.3), .fraction(0.1)])
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
//                StatusView()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StatusView: View {
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
            Text("간선 1234")
            Text("청강리공영차고지 ↔ 광안역")
            BusstopSearchTextField(busStopSearchText: $busStopSearchText)
                .padding(.horizontal, 20)
            Divider()
            HStack(alignment: .center, spacing: 20) {
                Text("1/2")
                    .foregroundStyle(.gray300)
                Spacer()
                Ellipse()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.gray200)
                    .overlay(
                        Image("bt_up")
                    )
               
                Ellipse()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.mainpurple)
                    .overlay(
                        Image("bt_down")
                    )
                Spacer()
                Text("정류장 선택")
                    .foregroundStyle(.mainpurple)
            }
            .padding(EdgeInsets(top: 15, leading: 20, bottom: 37, trailing: 20))
        }
    }
}

#Preview {
    AlarmSettingView()
}
