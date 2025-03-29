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

    private init() {
        setupAudioSession()
    }

    /// 오디오 세션 설정 (무음 모드에서도 소리 나오게)
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, // 무음 모드에서 소리가 나도록 설정
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
    }

    // 오디오 재생 (볼륨 조절 가능)
    func playSound(fileName: String, volume: Float = 1.0, fileType: String = "mp3") {
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileType) else {
            print("파일을 찾을 수 없음: \(fileName).\(fileType)")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player?.volume = max(0.0, min(volume, 1.0)) // 개별 오디오 볼륨 조절
            player?.play()
            
            // 시스템 볼륨 변경 (0.0~1.0 범위 내에서)
            setSystemVolume(volume)
            
            print("오디오 재생 (볼륨: \(player?.volume ?? 0.0))")
        } catch {
            print("오디오 재생 실패: \(error)")
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
                slider.value = max(0.0, min(volume, 1.0)) // 볼륨 값 제한
            }
        }
    }
}
