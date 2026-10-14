//
//  HotChaRadius.swift
//
//  앱과 위젯이 함께 쓰는 모서리 반경. 두 타깃이 이 파일 하나를 함께 컴파일한다.
//

import CoreGraphics

/// 모서리 반경. 앱과 위젯의 모든 둥근 모서리는 이 셋 중 하나다. 숫자를 직접 적지 않는다.
enum HotChaRadius {
    /// 카드 · 배너 · 큰 버튼
    static let card: CGFloat = 12
    /// 아이콘 타일 같은 작은 면
    static let tile: CGFloat = 8
    /// 버스 번호 배지
    static let badge: CGFloat = 4
}
