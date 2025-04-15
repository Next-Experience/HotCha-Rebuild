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
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let isSmall = height < 150
            let isMedium = height >= 250 && height < 600
            let isLarge = height >= 600
            
            VStack(alignment: .leading, spacing: 0) {
                
                if isMedium || isLarge {
                    BusStopInfoSection()
                }
                
                // 중간 이상 크기일 때만 표시
                if isMedium || isLarge {
                    BusStopDestinationSection()
                        .environmentObject(busStopSeoulViewModel)
                }
                
                if isLarge {
                    AlertSettingSection()
                }
                Spacer()
                Divider()
                AlertStopsSection()
                
                
                
            }
            .font(.pretendard(.semibold, size: 16))
        }
    }
}
struct BusStopDestinationSection: View {
    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager // modal sheet를 여닫음
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        VStack(spacing: 0){
            // 첫 번째 정류장
            Button(action: {
                modalStateViewModel.modalState = .alarmWait
                sheetManager.showAlarmInfoSheet2 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    sheetManager.showAlarmSearchSheet1 = true
                    busStopSeoulViewModel.switchToDestinationMode()
                }
            }){
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
            }
            
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
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
    }
    
}

struct AlertSettingSection: View {
    @State private var soundToggle = false
    @State private var vibrationToggle = false
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
    var body: some View {
        HStack(alignment: .bottom){
            Text("6정거장 전")
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(.gray900)
            Spacer()
            Text("알림 종료")
                .foregroundStyle(.mainpurple)
                .font(.pretendard(.medium, size: 16))
        }
        .padding(EdgeInsets(top: 21, leading: 20, bottom: 48, trailing: 20))
    }
}


struct BusStopInfoSection: View {
    @State var isFavorite: Bool = false
    //    @State var startStationName: String? = "시작역 없음"
    //    @State var endStationName: String? = "도착역 없음"
    //    @State var busNumber: String? = "버스번호 없음"
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    
    var body: some View {
        VStack(alignment:. leading, spacing: 12){
            HStack (alignment: .center){
                Text(modalStateViewModel.bus?.busRouteNm ?? "버스번호 없음")
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


//
//#Preview {
//    AlarmSettingView()
//}
