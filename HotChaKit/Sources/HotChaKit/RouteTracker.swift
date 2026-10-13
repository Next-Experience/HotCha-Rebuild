import Foundation

/// 노선 알람의 규칙. 내 위치로 지금 몇 번째 정류장인지 따라가다가 목적지 N정류장 전에 알람을 낸다.
///
/// 정류장은 노선 순서대로 들어온다고 보고 **배열의 자리(index)** 로만 센다.
/// 순번(seq) 값은 API 마다 1 부터일 수도 1001 부터일 수도 있어 빼기에 쓰지 않는다.
public struct RouteTracker: Sendable {
    /// 정류장에 도착했다고 보는 반경(m)
    public static let detectionRadius = 200.0
    /// GPS 가 튀거나 한 정류장을 놓쳐도 따라잡도록 함께 보는, 앞쪽 정류장 수
    public static let lookahead = 4
    /// 왕복 노선이 같은 자리를 두 번 지날 때 "같은 자리" 로 치는 거리 차(m)
    public static let sameSpotMargin = 60.0

    public let stops: [GeoPoint]
    public let destinationIndex: Int
    /// 사용자가 고른 "몇 정류장 전에 알릴지"
    public let alarmStopsBefore: Int

    public private(set) var currentIndex: Int?
    public private(set) var alarmFired = false
    /// 실제로 알람을 내는 남은 정류장 수. 이미 그보다 가까이서 시작하면 한 정류장 전으로 줄인다.
    public private(set) var alarmThreshold = 0

    public struct Update: Equatable, Sendable {
        public let currentIndex: Int
        /// 목적지까지 남은 정류장 수. 지나치면 음수다.
        public let remaining: Int
        /// 출발 정류장을 막 정한 첫 갱신인가
        public let isFirstFix: Bool
        /// 이번 갱신에서 알람을 울려야 하는가. 한 번만 true 가 된다.
        public let shouldFireAlarm: Bool
    }

    public init?(stops: [GeoPoint], destinationIndex: Int, alarmStopsBefore: Int) {
        guard stops.indices.contains(destinationIndex), alarmStopsBefore >= 0 else { return nil }
        self.stops = stops
        self.destinationIndex = destinationIndex
        self.alarmStopsBefore = alarmStopsBefore
    }

    /// 알람 정류장의 자리. 노선 앞쪽 끝을 넘지 않는다.
    public var alarmStopIndex: Int {
        max(destinationIndex - alarmStopsBefore, 0)
    }

    /// 새 위치를 받아 현재 정류장과 알람 여부를 갱신한다.
    public mutating func update(location: GeoPoint) -> Update {
        let isFirstFix = currentIndex == nil
        let index: Int
        if let current = currentIndex {
            index = advancedIndex(from: current, location: location) ?? current
        } else {
            index = startingIndex(from: location)
        }
        currentIndex = index

        let remaining = destinationIndex - index
        if isFirstFix {
            alarmThreshold = min(alarmStopsBefore, max(remaining - 1, 0))
        }
        // 정확히 N정류장일 때만 보면 한 정류장을 건너뛰었을 때 영영 울리지 않는다.
        let shouldFire = !alarmFired && remaining <= alarmThreshold
        if shouldFire {
            alarmFired = true
        }
        return Update(currentIndex: index, remaining: remaining, isFirstFix: isFirstFix, shouldFireAlarm: shouldFire)
    }

    /// 내 위치에서 가장 가까운 정류장을 출발 정류장으로 본다.
    /// 목적지를 이미 지난 정류장은 후보가 아니고, 거의 같은 거리의 후보가 여럿이면 목적지 쪽을 고른다.
    private func startingIndex(from location: GeoPoint) -> Int {
        let candidates = (0...destinationIndex).map { (index: $0, distance: location.distance(to: stops[$0])) }
        let nearest = candidates.map(\.distance).min() ?? 0
        return candidates.last { $0.distance <= nearest + Self.sameSpotMargin }?.index ?? 0
    }

    /// 지금 정류장보다 앞에 있는 정류장 중, 도착 반경 안에 들어온 가장 가까운 정류장
    private func advancedIndex(from current: Int, location: GeoPoint) -> Int? {
        let ahead = stops.indices.dropFirst(current + 1).prefix(Self.lookahead)
        return ahead
            .map { (index: $0, distance: location.distance(to: stops[$0])) }
            .filter { $0.distance <= Self.detectionRadius }
            .min { $0.distance < $1.distance }?
            .index
    }
}
