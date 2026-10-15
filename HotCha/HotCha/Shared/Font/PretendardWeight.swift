//
//  PretendardWeight.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//
import SwiftUI

extension Font {
    /// 기존 호출부를 유지하면서 모든 화면을 SF Pro 시스템 폰트로 전환한다.
    enum PretendardWeight {
        case black
        case bold
        case heavy
        case ultraLight
        case light
        case medium
        case regular
        case semibold
        case thin
        
        var systemWeight: Font.Weight {
            switch self {
            case .black:
                return .black
            case .bold:
                return .bold
            case .heavy:
                return .heavy
            case .ultraLight:
                return .ultraLight
            case .light:
                return .light
            case .medium:
                return .medium
            case .regular:
                return .regular
            case .semibold:
                return .semibold
            case .thin:
                return .thin
            }
        }
    }

    static func pretendard(_ weight: PretendardWeight, size fontSize: CGFloat) -> Font {
        .system(size: fontSize, weight: weight.systemWeight)
    }
}
