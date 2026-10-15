import Foundation

/// 위경도 한 점
public struct GeoPoint: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 두 점 사이의 거리(m). 정류장 간격 수준에서는 하버사인으로 충분하다.
    public func distance(to other: GeoPoint) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

public extension Array where Element == GeoPoint {
    /// 정류장을 순서대로 이은 길이(m). 자리가 뒤집혔거나 범위를 벗어나면 0 이다.
    func pathLength(from start: Int, to end: Int) -> Double {
        guard indices.contains(start), indices.contains(end), start < end else { return 0 }
        return (start..<end).reduce(0) { $0 + self[$1].distance(to: self[$1 + 1]) }
    }
}
