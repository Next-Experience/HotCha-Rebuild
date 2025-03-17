//
//  PushNotificationFunc.swift
//  HotCha
//
//  Created by 문재윤 on 3/17/25.
//

import UserNotifications

func sendPushNotification(title: String, body: String, sound: String, delay: TimeInterval = 5) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    
    // 사운드 설정 (사용자가 "default"를 입력하면 기본 사운드 사용)
    if sound.lowercased() == "default" {
        content.sound = .default
    } else {
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
    }

    // 지정된 시간 후 알림 전송
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
    // 저기 등록하면 실행되는 것
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("푸쉬 알림 전송 실패: \(error.localizedDescription)")
        }
    }
}

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("알림 권한 허용됨")
        } else {
            print("알림 권한 거부됨")
        }
    }
}
