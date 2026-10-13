//
//  Soundmanager.swift
//  HotCha
//
//  Created by 문재윤 on 3/29/25.
//
import AVFoundation
import MediaPlayer
import UIKit

class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    private let volumeView = MPVolumeView()
    private var originalVolume: Float = 1.0

    private init() {
        setupAudioSession()
    }

    /// 오디오 세션 설정 (무음 모드 및 백그라운드에서 재생 가능하게)
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers] // 🔊 다른 앱 오디오 줄이기
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try session.overrideOutputAudioPort(.speaker) // 🔊 스피커로 출력
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
    }

    // 오디오 재생 (볼륨 조절 가능)
    func playSound(fileName: String, volume: Float = 1.0, fileType: String = "mp3") {
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileType) else {
            print("❌ 파일을 찾을 수 없음: \(fileName).\(fileType)")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player?.volume = max(0.0, min(volume, 1.0))
            player?.numberOfLoops = -1 // 🔁 무한 반복
            player?.prepareToPlay() // 🧠 사전 준비
            player?.play()
            
            setSystemVolume(volume) // 시스템 볼륨 조절

            print("✅ 오디오 재생 시작 (볼륨: \(player?.volume ?? 0.0))")
        } catch {
            print("❌ 오디오 재생 실패: \(error)")
        }
    }

    // 오디오 정지
    func stopSound() {
        player?.stop()
    }

    // 시스템 볼륨 조절 (MPVolumeView 사용)
    func setSystemVolume(_ volume: Float) {
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.async {
                slider.value = max(0.0, min(volume, 1.0))
            }
        }
    }
}
