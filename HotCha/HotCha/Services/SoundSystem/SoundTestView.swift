//
//  SoundTestView.swift
//  HotCha
//
//  Created by 문재윤 on 3/29/25.
//


import SwiftUI
import AVFoundation
import MediaPlayer

struct SoundTestView: View {
    @State private var isPlaying = false
    @State private var currentVolume: Float = 0.5
    let soundManager = SoundManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Button(isPlaying ? "🔴 중지" : "▶️ 재생") {
                if isPlaying {
                    soundManager.stopSound()
                } else {
                    soundManager.playSound(fileName: "AlarmSound", volume: currentVolume)
                }
                isPlaying.toggle()
            }
            .font(.title)
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            HStack {
                Button("🔉 -") {
                    currentVolume = max(currentVolume - 0.1, 0.0)
                    soundManager.setSystemVolume(currentVolume)
                }
                .frame(width: 50, height: 50)

                Button("🔊 +") {
                    currentVolume = min(currentVolume + 0.1, 1.0)
                    soundManager.setSystemVolume(currentVolume)
                }
                .frame(width: 50, height: 50)
            }
        }
    }
}

#Preview {
    SoundTestView()
}
