//
//  DoAlarmView.swift
//  HotCha
//
//  Created by 문호 on 4/24/25.
//

import SwiftUI

struct DoAlarmView: View {
    // UserDefaults에서 알람 정보 가져오기
    @State private var busNumber: String = UserDefaults.standard.string(forKey: "alarmBusNo") ?? "500"
    @State private var busType: String = UserDefaults.standard.string(forKey: "alarmBusType") ?? "1"
    @State private var destinationStop: String = UserDefaults.standard.string(forKey: "alarmDestination") ?? "남대문시장앞.이회영활동터"
    @State private var remainingStops: Int = UserDefaults.standard.integer(forKey: "alarmRemainingStops")
    
    var body: some View {
        VStack {
            HStack {
                Text("목적지까지")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("gray900"))
                
                Text("\(remainingStops)") // AlarmStatusView AlertStopsSection 구조체 참조
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("mainpurple"))
                
                Text("정거장 남았어요")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("gray900"))
                Spacer()
            }
            
            HStack {
                SearchBusUtil.CustomBusNoView(busNo: busNumber, routeType: busType)
                Text(destinationStop)
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(.gray900)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.mainpurple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mainpurple.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mainpurple, lineWidth: 2)
                    )
            )
            .onAppear {
                // 데이터 갱신
                busNumber = UserDefaults.standard.string(forKey: "alarmBusNo") ?? "500"
                busType = UserDefaults.standard.string(forKey: "alarmBusType") ?? "4"
                destinationStop = UserDefaults.standard.string(forKey: "alarmDestination") ?? "남대문시장앞.이회영활동터"
                remainingStops = UserDefaults.standard.integer(forKey: "alarmRemainingStops")
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AlarmStatusChanged"))) { _ in
                // 알람 상태가 변경되었을 때 데이터 갱신
                busNumber = UserDefaults.standard.string(forKey: "alarmBusNo") ?? "500"
                busType = UserDefaults.standard.string(forKey: "alarmBusType") ?? "4"
                destinationStop = UserDefaults.standard.string(forKey: "alarmDestination") ?? "남대문시장앞.이회영활동터"
                remainingStops = UserDefaults.standard.integer(forKey: "alarmRemainingStops")
            }
        }
    }
}

#Preview {
    DoAlarmView()
}
