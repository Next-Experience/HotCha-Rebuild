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

func startAlarm(title: String, body: String, useSound: Bool, useVibration: Bool) {
    // 사운드 파일 이름 (SoundManager에서 재생할 사운드 파일)
    let soundFileName = "AlarmSound" // 앱에 포함된 mp3 파일 이름 (alarm.mp3)

    // 푸시 알림에 사용할 사운드 설정
    var notificationSound: String
    if useSound {
        notificationSound = "default" // 푸시 알림에서는 기본 사운드 사용
        SoundManager.shared.playSound(fileName: soundFileName) // 실제 사운드 재생
    } else if !useVibration {
        notificationSound = "novibration" // 사운드도 진동도 없음
    } else {
        // 진동만 사용하고 싶을 경우 (푸시 사운드는 비우고, 기기 진동 처리)
        notificationSound = "novibration"
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // 진동만 울리기
    }

    // 푸시 알림 전송
    sendPushNotification(title: title, body: body, sound: notificationSound)
}
