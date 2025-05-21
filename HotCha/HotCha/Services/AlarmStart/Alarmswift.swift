//
//  Alarmswift.swift
//  HotCha
//
//  Created by 문재윤 on 4/24/25.
//
import SwiftUI
import UIKit
import AVFoundation
import MediaPlayer
import UserNotifications
import AudioToolbox
var alarmTimer: Timer? // 전역 또는 클래스 내부 프로퍼티로 선언

func startAlarm(title: String, body: String, useSound: Bool, useVibration: Bool) {
    let soundFileName = "AlarmSound"

    var notificationSound: String
    if useSound {
        notificationSound = "default"
        SoundManager.shared.playSound(fileName: soundFileName)
    } else if !useVibration {
        notificationSound = "novibration"
    } else {
        notificationSound = "novibration"
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    sendPushNotification(title: title, body: body, sound: notificationSound)
    

    
}

func startAlarmToggle(isOn: Bool, title: String, body: String, useSound: Bool, useVibration: Bool) {
    if isOn {
        // 알람 시작\
        startAlarm(title: title, body: body, useSound: useSound, useVibration: useVibration)

        // 2초 간격으로 푸시 알림 반복
        alarmTimer?.invalidate() // 기존 타이머가 있다면 무효화
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            startAlarm(title: title, body: body, useSound: useSound, useVibration: useVibration)
        }
        
        for i in 1..<10 {
            sendPushNotification(
                title: title,
                body: body,
                sound: "default",
                delay: Double(i) * 3
            )
        }
        print("알람이 시작")
    } else {
        // 알람 종료
        SoundManager.shared.stopSound()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 현재 화면에 표시된 알림도 제거 (선택사항)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        alarmTimer?.invalidate()
        alarmTimer = nil
        print("⏹ 알람 정지됨")
    }
}
