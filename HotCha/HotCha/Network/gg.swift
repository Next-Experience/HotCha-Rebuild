//
//  ㅣㅣ.swift
//  HotCha
//
//  Created by 문재윤 on 5/21/25.
//

import SwiftUI

struct AlarmTestView: View {
    @State private var alarmStopDistanceFromDestination = 2
    @State private var soundToggle = true
    @State private var vibrationToggle = true

    var body: some View {
        VStack(spacing: 20) {
            Button("🚨 알람 시작") {
                sendPushNotification(title: "title", body: "body", sound: "notificationSound")
                print("zㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ")
                for i in 1..<10 {
                    sendPushNotification(
                        title: "알림 \(i + 1)",
                        body: "도착까지 \(alarmStopDistanceFromDestination)정류장 남았어요!",
                        sound: "default",
                        delay: Double(i) * 3
                    )
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("🛑 알람 종료") {
                // 예약된 모든 알림 제거
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    
                    // 현재 화면에 표시된 알림도 제거 (선택사항)
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                requestNotificationPermission()
                startAlarmToggle(
                    isOn: false,
                    title: "",
                    body: "",
                    useSound: false,
                    useVibration: false
                )
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }


}

#Preview {
    AlarmTestView()
}
