//
//  TrainStationCatalog.swift
//  HotCha
//
//  앱에 내장된 TrainStations.json (기차역 이름 목록) 조회와, 고른 역의 좌표 확인.
//  파일은 Tools/build_train_stations.py 로 만든다.
//
//  검색은 내장 목록에서만 한다. 공공데이터의 역 좌표는 수십 km 씩 틀린 역이 있어 「어디쯤」 으로만 믿고,
//  알람에 쓰는 좌표는 역을 고를 때 MapKit 으로 그 근처에서 다시 찾는다 (결정 0006).
//

import CoreLocation
import Foundation
import MapKit

/// 내장 목록의 기차역 하나
struct TrainStation: Identifiable, Hashable, Decodable {
    /// "대전" · "김천(구미)" — 끝의 「역」 은 뺀 이름
    let name: String
    /// 지나는 노선. 많으면 앞의 셋만 있다. 비어 있을 수 있다.
    let lines: [String]
    /// 코레일 지역본부 또는 공단 지사. 노선이 없을 때 대신 보여 준다.
    let region: String
    /// 공공데이터가 말하는 역 위치들. 서로 다를 수 있다. MapKit 결과를 고르는 기준으로만 쓴다.
    let hints: [[Double]]
    /// 두 공공 파일이 1km 안에서 일치한 좌표. MapKit 을 못 쓸 때 이것으로 대신한다.
    let coord: [Double]?

    var id: String { name }

    /// 화면에 보이는 이름. "대전역"
    var displayName: String { "\(name)역" }

    /// "경부선 · 호남선" 처럼 어느 역인지 가려 볼 한 줄
    var detail: String {
        lines.isEmpty ? region : lines.joined(separator: " · ")
    }

    fileprivate var hintCoordinates: [CLLocationCoordinate2D] {
        hints.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) : nil }
    }

    /// MapKit 에 넣을 검색어. "김천(구미)" 는 "김천구미역" 을 먼저, 안 되면 "김천역" 을 찾는다.
    fileprivate var queries: [String] {
        let flat = name.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        let base = name.components(separatedBy: "(").first ?? name
        return flat == base ? ["\(base)역"] : ["\(flat)역", "\(base)역"]
    }
}

enum TrainStationCatalog {
    /// MapKit 결과가 공공데이터 위치에서 이만큼 안이어야 같은 역으로 본다. 역사를 옮긴 역(원주 · 안동)은 5km 쯤 어긋난다.
    static let matchRadius: CLLocationDistance = 8_000

    static let all: [TrainStation] = {
        guard let url = Bundle.main.url(forResource: "TrainStations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let stations = try? JSONDecoder().decode([TrainStation].self, from: data)
        else { return [] }
        return stations
    }()

    /// 이름으로 찾는다. 「역」 은 붙여도 안 붙여도 된다. 같은 이름 → 앞이 같은 이름 → 이름에 든 것 순이다.
    static func search(_ text: String) -> [TrainStation] {
        let query = normalized(text)
        guard !query.isEmpty else { return [] }
        let ranked: [(rank: Int, station: TrainStation)] = all.compactMap { station in
            rank(of: station, for: query).map { (rank: $0, station: station) }
        }
        return ranked.sorted { lhs, rhs in
            lhs.rank != rhs.rank ? lhs.rank < rhs.rank : lhs.station.name < rhs.station.name
        }
        .map(\.station)
    }

    /// 이 이름과 정확히 같은 역이 있나. 「대전역」 을 치면 정류장보다 기차역을 먼저 보여 줄지 정한다.
    static func hasExactMatch(_ text: String) -> Bool {
        let query = normalized(text)
        return all.contains { rank(of: $0, for: query) == 0 }
    }

    /// 띄어쓰기와 끝의 「역」 을 뺀다.
    private static func normalized(_ text: String) -> String {
        var query = text.replacingOccurrences(of: " ", with: "")
        if query.hasSuffix("역") { query.removeLast() }
        return query
    }

    /// 0 같은 이름 · 1 앞이 같음 · 2 이름에 들어 있음 · nil 아님
    private static func rank(of station: TrainStation, for query: String) -> Int? {
        guard !query.isEmpty else { return nil }
        let plain = station.name.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if station.name == query || plain == query { return 0 }
        if station.name.hasPrefix(query) { return 1 }
        if plain.contains(query) { return 2 }
        return nil
    }

    /// 알람에 쓸 좌표를 정해 정류장 알람이 받는 모양으로 돌려준다.
    /// MapKit 으로 공공데이터 위치 근처의 대중교통 시설을 찾고, 가장 가까운 것을 고른다.
    /// 못 찾으면 두 공공 파일이 일치한 좌표로 대신한다. 그것도 없으면 nil 이다.
    static func resolve(_ station: TrainStation) async -> BusStopRecord? {
        let hints = station.hintCoordinates
        guard !hints.isEmpty else { return fallback(station) }
        for query in station.queries {
            if let coordinate = await nearestPlace(query, around: hints) {
                return record(station, coordinate: coordinate)
            }
        }
        return fallback(station)
    }

    private static func fallback(_ station: TrainStation) -> BusStopRecord? {
        guard let coord = station.coord, coord.count == 2 else { return nil }
        return record(station, coordinate: CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1]))
    }

    private static func record(_ station: TrainStation, coordinate: CLLocationCoordinate2D) -> BusStopRecord {
        BusStopRecord(
            id: "train-\(station.name)", name: station.displayName, latitude: coordinate.latitude,
            longitude: coordinate.longitude, arsNumber: "", cityName: station.detail, isTrainStation: true)
    }

    private static func nearestPlace(_ query: String, around hints: [CLLocationCoordinate2D]) async
        -> CLLocationCoordinate2D?
    {
        let lats = hints.map(\.latitude)
        let lons = hints.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max()
        else { return nil }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // 같은 이름의 지하철역(김포 골드라인 마산역 같은)이 먼저 나오지 않도록 공공데이터 위치 둘레만 찾는다.
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: maxLat - minLat + 0.3, longitudeDelta: maxLon - minLon + 0.3))
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
        guard let items = try? await MKLocalSearch(request: request).start().mapItems else { return nil }
        let candidates = items.map { item -> (CLLocationCoordinate2D, CLLocationDistance) in
            let coordinate = item.location.coordinate
            let place = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let nearest = hints.map {
                place.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
            }.min() ?? .infinity
            return (coordinate, nearest)
        }
        return candidates.filter { $0.1 <= matchRadius }.min { $0.1 < $1.1 }?.0
    }
}
