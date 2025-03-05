//
//  AlarmSettingView.swift
//  HotCha
//
//  Created by Yeji Seo on 2/8/25.
//
import SwiftUI

struct AlarmSettingView: View {
    @State var showSheet: Bool = true
    @State private var selectedDetent: PresentationDetent = .fraction(0.4)
    
    var body: some View {
        BusStopListView()
            .sheet(isPresented: $showSheet) {
                ModalView()
                    .interactiveDismissDisabled(true)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.99), .fraction(0.4), .fraction(0.32), .fraction(0.1)], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(20)
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
                
//                                BusStopSearchView()
                AlarmStatusView()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct AlarmStatusView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 정류장 정보 리스트
            VStack(spacing: 0) {
                BusStopInfoSection()
                    .padding(.vertical, 16)
                // 첫 번째 정류장
                HStack {
                    Image("map_pin")
                        .frame(width: 16, height: 16)
                        .foregroundColor(.mainpurple)
                        .padding(.leading,16)
                    
                    Text("올림픽교차로(광안역방면)")
                        .font(.system(size: 16))
                        .padding(.vertical, 16)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .background(.gray150)
                
                Divider()
                
                // 두 번째 정류장
                HStack {
                    Image(systemName: "bell")
                        .frame(width: 16, height: 16)
                        .foregroundColor(.mainpurple)
                        .padding(.leading, 16)
                    
                    Text("용궁사, 국립수산과학원")
                        .font(.system(size: 16))
                        .padding(.vertical, 16)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray300)
                        .padding(.trailing, 16)
                }
                .background(.gray150)
            }
            .cornerRadius(8)
            .padding(.horizontal)
            
            Divider()
            AlertStopsSection()
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 48, trailing: 20))
        }
    }
}

struct AlertStopsSection: View {
    var body: some View {
        HStack (alignment: .bottom){
            Text("6정거장 전")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            Spacer()
            Text("알림 종료")
                .foregroundStyle(.mainpurple)
                .font(.pretendard(.medium, size: 16))
        }
    }
}

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

struct BusStopInfoSection: View {
    @State var isFavorite: Bool = false
    
    var body: some View {
        VStack(alignment:. leading, spacing: 12){
            HStack (alignment: .center){
                Text("간선 1234")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(.skybluec)
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .background(RoundedRectangle(cornerRadius: 4).fill(.skybluec.opacity(0.2)))
                Spacer()
                Button(action: {
                    isFavorite.toggle()
                }) {
                    Image(isFavorite ? "star_fill" : "star_empty")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
                
            }
            HStack(spacing: 6){
                Text("청강리공영차고지")
                Text("↔")
                Text("광안역")
            }
            .font(.pretendard(.semibold, size: 18))
            .foregroundStyle(.gray600)
            .padding(.bottom, 4)
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


#Preview {
    AlarmSettingView()
}
