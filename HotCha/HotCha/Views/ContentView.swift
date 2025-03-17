//
//  ContentView.swift
//  HotCha
//
//  Created by 문재윤 on 3/17/25.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("푸쉬 알림 보내기") {
                sendPushNotification(
                    title: "ㅋㅋ",
                    body: "이것은 사용자 입력을 기반으로 보낸 푸쉬 알림입니다.",
                    sound: "default" // 또는 특정 사운드 파일 예: "custom_sound.caf"
                )
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

        }
        .onAppear {
            requestNotificationPermission()
        }
    }
}
