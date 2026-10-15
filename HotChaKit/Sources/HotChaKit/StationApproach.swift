import Foundation

/// 기차역 알람 규칙. 노선 없이 내릴 역 하나만 알고, 그 역까지의 직선 거리로 울린다.
///
/// 버스 정류장 알람과 다른 점은 터널이다. 고속선은 구간의 절반 이상이 터널이라 위치가 몇 분씩 끊긴다.
/// 내릴 역 바로 앞이 긴 터널이면 반경에 들어서는 순간을 보지 못한다. 그래서 반경 가까이에서 믿을 만한
/// 위치가 한동안 끊기면 반경에 들어온 것으로 보고 미리 울린다. 늦게 울리는 것보다 일찍 울리는 쪽이 낫다.
public struct StationApproach: Sendable {
    /// 이보다 흐린 위치(m)는 믿지 않는다. 터널 안에서는 기지국으로 잡은 수 km 짜리 위치가 온다.
    public static let trustedAccuracy: Double = 1_000
    /// 믿을 만한 위치가 이만큼(초) 없으면 신호가 끊긴 것으로 본다.
    public static let signalLossTimeout: TimeInterval = 90
    /// 마지막 위치가 반경의 이 배수 안이었을 때만 신호 끊김으로 미리 울린다.
    public static let signalLossFactor: Double = 2

    public enum Reason: Equatable, Sendable {
        /// 반경 안에 들어왔다
        case reached
        /// 반경 가까이에서 위치가 끊겼다
        case signalLost
    }

    public struct Update: Equatable, Sendable {
        /// 마지막으로 믿을 만했던 위치에서 역까지의 거리(m). 아직 없으면 nil
        public let distance: Double?
        /// 이번에 알람을 울려야 하는가. 안내 하나에 한 번만 true 다.
        public let shouldFireAlarm: Bool
        public let reason: Reason?
    }

    public let destination: GeoPoint
    public let radius: Double
    public private(set) var lastDistance: Double?
    public private(set) var lastTrustedFixAt: Date?
    public private(set) var alarmFired = false

    public init?(destination: GeoPoint, radius: Double) {
        guard radius > 0 else { return nil }
        self.destination = destination
        self.radius = radius
    }

    /// 새 위치. `accuracy` 는 CoreLocation 의 horizontalAccuracy(m)다. 음수면 위치가 아니다.
    public mutating func update(location: GeoPoint, accuracy: Double, at time: Date) -> Update {
        guard accuracy >= 0, accuracy <= Self.trustedAccuracy else { return tick(now: time) }
        let meters = location.distance(to: destination)
        lastDistance = meters
        lastTrustedFixAt = time
        return fire(if: meters <= radius, reason: .reached)
    }

    /// 위치가 오지 않아도 주기적으로 부른다. 신호 끊김은 위치가 아니라 시간으로만 알 수 있다.
    public mutating func tick(now: Date) -> Update {
        guard let lastDistance, let lastTrustedFixAt else { return fire(if: false, reason: .signalLost) }
        let lost = now.timeIntervalSince(lastTrustedFixAt) >= Self.signalLossTimeout
        return fire(if: lost && lastDistance <= radius * Self.signalLossFactor, reason: .signalLost)
    }

    private mutating func fire(if condition: Bool, reason: Reason) -> Update {
        guard condition, !alarmFired else {
            return Update(distance: lastDistance, shouldFireAlarm: false, reason: nil)
        }
        alarmFired = true
        return Update(distance: lastDistance, shouldFireAlarm: true, reason: reason)
    }
}
