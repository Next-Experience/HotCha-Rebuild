//
//  HotChaActivityAttributes.swift
//
//  Live Activity 의 데이터 모양. 앱과 위젯 익스텐션이 **이 파일 하나**를 함께 컴파일한다.
//  두 타깃에 따로 적으면 한쪽만 바뀌었을 때 컴파일은 되고 잠금 화면만 조용히 안 뜬다.
//

import ActivityKit
import Foundation

struct HotChaActivityAttributes: ActivityAttributes {
    enum Kind: String, Codable, Hashable {
        /// 버스를 골라 남은 정류장 수로 안내한다.
        case route
        /// 정류장만 골라 남은 거리로 안내한다.
        case stop
    }

    /// 안내하는 동안 바뀌는 값
    struct ContentState: Codable, Hashable {
        /// 남은 정류장 수 (노선 안내). 지나치면 음수다.
        var remainingStops: Int?
        /// 남은 거리 m (정류장 안내)
        var remainingMeters: Int?
        /// 지금 있는 정류장 이름. 정류장 안내에서는 비어 있다.
        var currentStop: String
        /// 알람이 울렸는가
        var hasAlarmFired: Bool
    }

    // 안내를 시작할 때 정해지고 바뀌지 않는 값
    var kind: Kind
    /// 버스 번호. 정류장 안내에서는 비어 있다.
    var busNumber: String
    /// 내릴 정류장 이름
    var destination: String
    /// 알람이 울리는 곳. "OO정류장" 또는 "500m 전"
    var alarmPoint: String
    /// 카드에 그릴 그림 이름. 노선 유형에 맞는 버스나 정류장 그림이다.
    /// 단계와 문구는 HotChaGuidance 가 정한다.
    var imageName: String
}
