//
//  HapticManager.swift
//  HotCha
//
//  Created by 문호 on 6/11/25.
//

import Foundation
import AudioToolbox
import UIKit

// MARK: - 햅틱 타입 정의
enum HapticType {
    case light      // 가벼운 햅틱
    case medium     // 중간 햅틱
    case heavy      // 강한 햅틱
    case selection  // 선택 피드백
    case success    // 성공 피드백
    case warning    // 경고 피드백
    case error      // 에러 피드백
    case classic    // 클래식 진동 (AudioServices)
}

// MARK: - 햅틱 매니저 클래스
class HapticManager {
    
    // 싱글톤 인스턴스
    static let shared = HapticManager()
    
    // 초기화 방지
    private init() {}
    
    // MARK: - 메인 햅틱 함수
    /// 지정된 타입의 햅틱을 실행합니다
    /// - Parameter type: 햅틱 타입
    func haptic(_ type: HapticType = .medium) {
        // 햅틱 설정이 꺼져있는지 확인
        guard isHapticEnabled() else { return }
        
        switch type {
        case .light:
            generateImpactFeedback(.light)
        case .medium:
            generateImpactFeedback(.medium)
        case .heavy:
            generateImpactFeedback(.heavy)
        case .selection:
            generateSelectionFeedback()
        case .success:
            generateNotificationFeedback(.success)
        case .warning:
            generateNotificationFeedback(.warning)
        case .error:
            generateNotificationFeedback(.error)
        case .classic:
            generateClassicVibration()
        }
    }
    
    // MARK: - 커스텀 햅틱 패턴
    /// 커스텀 햅틱 패턴을 실행합니다
    /// - Parameter pattern: 햅틱 지속시간과 대기시간의 배열 (밀리초)
    func hapticWithPattern(_ pattern: [Int]) {
        guard isHapticEnabled() else { return }
        
        for (index, duration) in pattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                if index % 2 == 0 { // 짝수 인덱스는 햅틱
                    self.generateImpactFeedback(.medium)
                }
                // 홀수 인덱스는 대기 (아무것도 안함)
            }
        }
    }
    
    // MARK: - Private 헬퍼 함수들
    
    /// Impact 피드백 생성
    private func generateImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Selection 피드백 생성
    private func generateSelectionFeedback() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
    
    /// Notification 피드백 생성
    private func generateNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(type)
    }
    
    /// 클래식 진동 (AudioServices 사용)
    private func generateClassicVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    /// 햅틱 설정 확인
    private func isHapticEnabled() -> Bool {
        // 시뮬레이터에서는 햅틱이 작동하지 않음
        #if targetEnvironment(simulator)
        print("햅틱은 실제 기기에서만 작동합니다.")
        return false
        #else
        return true
        #endif
    }
}

// MARK: - 전역 편의 함수들
/// 간단한 햅틱 함수 (전역에서 사용 가능)
func haptic(_ type: HapticType = .medium) {
    HapticManager.shared.haptic(type)
}

/// 가벼운 햅틱
func lightHaptic() {
    HapticManager.shared.haptic(.light)
}

/// 중간 햅틱
func mediumHaptic() {
    HapticManager.shared.haptic(.medium)
}

/// 강한 햅틱
func heavyHaptic() {
    HapticManager.shared.haptic(.heavy)
}

/// 성공 피드백
func successHaptic() {
    HapticManager.shared.haptic(.success)
}

/// 에러 피드백
func errorHaptic() {
    HapticManager.shared.haptic(.error)
}

/// 선택 피드백
func selectionHaptic() {
    HapticManager.shared.haptic(.selection)
}
