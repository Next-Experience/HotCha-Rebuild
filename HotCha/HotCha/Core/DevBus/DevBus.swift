//
//  DevBus.swift
//  HotCha
//
//  실기기에서 알람이 실제로 울리는지 자리에 앉아 확인하는 가짜 노선 9999번. 디버그 빌드에만 있다.
//  정류장은 노선을 열 때의 내 위치에서 북쪽으로 놓고, 안내 중에는 가짜 위치가 정류장을 차례로 밟는다.
//

#if DEBUG
import Combine
import CoreLocation
import Foundation

enum DevBus {
    static let routeId = "DEV-9999"
    static let number = "9999"
    /// 정류장 사이 거리(m). 전진 반경(200m)보다 멀어야 한 정류장씩 나아간다.
    static let spacing: CLLocationDistance = 300
    /// 가짜 위치가 다음 정류장으로 옮겨 가는 간격
    static let interval: TimeInterval = 8

    private static let stopNames = [
        "재윤이집",
        "재윤이네 편의점",
        "재윤이의 떡볶이집",
        "재윤이의 피시방",
        "재윤이네 코인노래방",
        "재윤이의 단골 카페",
        "재윤이네 헬스장",
        "재윤이의 국밥집",
        "재윤이네 공원",
        "재윤이회사"
    ]
    /// 위치를 모를 때 재윤이집으로 쓰는 곳. 서울시청이다.
    private static let fallback = CLLocationCoordinate2D(latitude: 37.5663, longitude: 126.9779)

    /// 검색어가 9999 의 앞부분이면 검색 결과 맨 위에 둔다.
    static func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && number.hasPrefix(trimmed)
    }

    static func isDevBus(routeId: String) -> Bool {
        routeId == Self.routeId
    }

    static var info: Bus_info_seoul {
        Bus_info_seoul(
            busRouteAbrv: number, busRouteId: routeId, busRouteNm: number, corpNm: "개발자",
            stStationNm: stopNames[0], edStationNm: stopNames[stopNames.count - 1],
            firstBusTm: "", firstLowTm: "", lastBusTm: "", lastBusYn: "", lastLowTm: "",
            length: "", routeType: "3", term: "", city_code: "1")
    }

    /// 재윤이집을 `origin` 에 두고 북쪽으로 정류장을 놓는다.
    static func stops(around origin: CLLocation?) -> [BusStop] {
        let start = origin?.coordinate ?? fallback
        let metersPerDegree = 111_320.0
        return stopNames.enumerated().map { index, name in
            BusStop(
                busRouteId: routeId,
                busRouteNm: number,
                seq: index + 1,
                station: "DEV-9999-\(index + 1)",
                stationNm: name,
                gpsX: start.longitude,
                gpsY: start.latitude + Double(index) * spacing / metersPerDegree,
                stationNo: 99_990 + index
            )
        }
    }

    /// 안내 중에 실제 위치 대신 쓰는 가짜 위치. 첫 정류장에서 바로 시작해 `interval` 마다 다음 정류장으로 간다.
    /// 마지막 정류장에 닿으면 더 내보내지 않는다.
    static func ride(along stops: [BusStop]) -> AnyPublisher<CLLocation, Never> {
        let locations = stops.map { CLLocation(latitude: $0.gpsY, longitude: $0.gpsX) }
        guard let first = locations.first else { return Empty().eraseToAnyPublisher() }
        let rest = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .zip(locations.dropFirst().publisher)
            .map { $0.1 }
        return Just(first).append(rest).eraseToAnyPublisher()
    }
}
#endif
