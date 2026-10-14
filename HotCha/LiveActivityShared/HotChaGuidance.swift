//
//  HotChaGuidance.swift
//
//  안내 하나의 지금 단계와 문구. 홈 배너(앱)와 잠금 화면 · 다이내믹 아일랜드(위젯)가 같은 말을 하도록
//  두 타깃이 이 파일 하나를 함께 컴파일한다. 화면 모양은 각자 따로 그린다.
//  단계는 실제로 아는 값으로만 정한다. 승차 여부는 알 수 없으므로 「탑승 중」이나 예상 도착 시간은 없다.
//

import Foundation

struct HotChaGuidance: Equatable {
    enum Phase: Equatable {
        /// 안내를 시작했고 아직 위치를 못 받았다
        case locating
        /// 알람 전
        case travelling
        /// 알람이 울렸고 아직 내릴 정류장 전이다
        case preparing
        /// 남은 정류장이 0이다
        case arrived
        /// 내릴 정류장을 지났다
        case passed
    }

    var kind: HotChaActivityAttributes.Kind
    /// 버스 번호. 정류장 안내에서는 비어 있다.
    var busNumber: String
    var destination: String
    /// 남은 정류장 수 (노선 안내). 지나치면 음수다.
    var remainingStops: Int?
    /// 남은 거리 m (정류장 안내)
    var remainingMeters: Int?
    var hasAlarmFired: Bool

    var phase: Phase {
        if let stops = remainingStops {
            if stops < 0 { return .passed }
            if stops == 0 { return .arrived }
            return hasAlarmFired ? .preparing : .travelling
        }
        if remainingMeters != nil {
            return hasAlarmFired ? .preparing : .travelling
        }
        return .locating
    }

    /// 맨 위 작은 글자. "152번" · "정류장 알림"
    var label: String {
        kind == .route ? "\(busNumber)번" : "정류장 알림"
    }

    /// 큰 글자 옆 꼬리표. 알람 뒤 단계에만 있다.
    var phaseTag: String? {
        switch phase {
        case .preparing: return "하차 준비"
        case .arrived: return "도착"
        case .passed: return "지나침"
        case .locating, .travelling: return nil
        }
    }

    /// 가장 크게 보여 줄 한 줄. "3정류장 남았어요" · "540m 남았어요"
    var headline: String {
        switch phase {
        case .locating: return "위치 확인 중"
        case .arrived: return "이번 정류장이에요"
        case .passed: return "\(-(remainingStops ?? 0))정류장 지났어요"
        case .travelling, .preparing:
            if let stops = remainingStops { return "\(stops)정류장 남았어요" }
            return "\(Self.format(meters: remainingMeters ?? 0)) 남았어요"
        }
    }

    /// 큰 글자의 숫자 부분. 잠금 화면은 이것만 더 크게 그린다. "3" · "540m". 숫자가 없는 단계는 nil
    var headlineNumber: String? {
        switch phase {
        case .locating, .arrived: return nil
        case .passed: return "\(-(remainingStops ?? 0))"
        case .travelling, .preparing:
            if let stops = remainingStops { return "\(stops)" }
            return Self.format(meters: remainingMeters ?? 0)
        }
    }

    /// 큰 글자에서 숫자를 뺀 나머지. "정류장 남았어요" · "남았어요" · "이번 정류장이에요"
    var headlineRest: String {
        guard let number = headlineNumber else { return headline }
        return String(headline.dropFirst(number.count)).trimmingCharacters(in: .whitespaces)
    }

    /// 아래 한 줄. "두산위브아파트입구에서 내려요" · "미아초교를 지났어요"
    var detail: String {
        phase == .passed ? "\(destination)\(Self.objectParticle(after: destination)) 지났어요" : "\(destination)에서 내려요"
    }

    /// 마지막 글자에 받침이 있으면 "을", 없으면 "를". 한글로 끝나지 않으면 받침이 있는 것으로 본다.
    static func objectParticle(after word: String) -> String {
        guard let last = word.unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else { return "을" }
        return (last.value - 0xAC00) % 28 == 0 ? "를" : "을"
    }

    /// 좁은 자리의 남은 양. "3" · "540m" · "도착" · "지남"
    var compact: String {
        switch phase {
        case .locating: return "…"
        case .arrived: return "도착"
        case .passed: return "지남"
        case .travelling, .preparing:
            if let stops = remainingStops { return "\(stops)정류장" }
            return Self.format(meters: remainingMeters ?? 0)
        }
    }

    /// 하차벨을 보여 줄 단계인가. 아니면 버스(정류장) 그림이다.
    var showsStopBell: Bool {
        switch phase {
        case .preparing, .arrived, .passed: return true
        case .locating, .travelling: return false
        }
    }

    static func format(meters: Int) -> String {
        guard meters >= 1000 else { return "\(meters)m" }
        let km = (Double(meters) / 100).rounded() / 10
        return km == km.rounded() ? "\(Int(km))km" : String(format: "%.1fkm", km)
    }
}

extension HotChaGuidance {
    /// Live Activity 의 고정값과 바뀌는 값으로 만든다.
    init(attributes: HotChaActivityAttributes, state: HotChaActivityAttributes.ContentState) {
        self.init(
            kind: attributes.kind,
            busNumber: attributes.busNumber,
            destination: attributes.destination,
            remainingStops: state.remainingStops,
            remainingMeters: state.remainingMeters,
            hasAlarmFired: state.hasAlarmFired
        )
    }
}
