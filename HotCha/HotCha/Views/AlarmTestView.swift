////
////  AlarmTestView.swift
////  HotCha
////
////  Created by 문재윤 on 4/24/25.
////
//
//
//import SwiftUI
//
//struct AlarmToggleView: View {
//    @State private var isAlarmOn = false
//    @State private var useSound = true
//    @State private var useVibration = true
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("🔁 알람 토글")
//                .font(.largeTitle)
//                .bold()
//            
//            Toggle("소리 재생", isOn: $useSound)
//            Toggle("진동 사용", isOn: $useVibration)
//            
//            Toggle("알람 켜기", isOn: $isAlarmOn)
//                .onChange(of: isAlarmOn) { newValue in
//                    requestNotificationPermission()
//                    startAlarmToggle(
//                        isOn: newValue,
//                        title: "알람 토글 테스트",
//                        body: newValue ? "알람이 시작됩니다!" : "알람이 꺼졌습니다.",
//                        useSound: useSound,
//                        useVibration: useVibration
//                    )
//                }
//                .padding()
//        }
//        .padding()
//    }
//}
import SwiftUI

struct AlarmToggleView: View {
    @State private var isAlarmOn = false
    @State private var useSound = false
    @State private var useVibration = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔁 알람 토글")
                .font(.largeTitle)
                .bold()
            
            Toggle("소리 재생", isOn: $useSound)
            Toggle("진동 사용", isOn: $useVibration)
            
            Toggle("알람 켜기", isOn: $isAlarmOn)
                .onChange(of: isAlarmOn) { newValue in
                    requestNotificationPermission()
                    startAlarmToggle(
                        isOn: newValue,
                        title: "알람 토글 테스트",
                        body: newValue ? "알람이 시작됩니다!" : "알람이 꺼졌습니다.",
                        useSound: useSound,
                        useVibration: useVibration
                    )
                }
                .padding()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isAlarmOn = true
            }
        }
    }
}
