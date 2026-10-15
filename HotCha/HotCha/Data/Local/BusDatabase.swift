//
//  BusDatabase.swift
//  HotCha
//
//  앱에 내장된 BusData.sqlite (전국 정류장 + 노선 목록) 조회.
//  파일은 Tools/build_bus_db.py 로 만든다.
//

import CoreLocation
import Foundation
import SQLite3

/// 내장 DB 의 정류장 한 곳
struct BusStopRecord: Identifiable, Hashable, Codable {
    let id: String  // 정류장 ID (예: DGB7011025300)
    let name: String
    let latitude: Double
    let longitude: Double
    let arsNumber: String  // 정류장에 적힌 모바일 단축번호
    let cityName: String
    /// 버스 정류장이 아니라 기차역이다. 기차역은 내장 DB 가 아니라 `TrainStationCatalog` 에서 온다.
    /// 알람 반경 · 위치 추적 · 문구가 달라진다. 이 값이 생기기 전에 저장한 기록에는 없어서 false 로 읽는다.
    var isTrainStation = false

    init(
        id: String, name: String, latitude: Double, longitude: Double, arsNumber: String, cityName: String,
        isTrainStation: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.arsNumber = arsNumber
        self.cityName = cityName
        self.isTrainStation = isTrainStation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        arsNumber = try container.decode(String.self, forKey: .arsNumber)
        cityName = try container.decode(String.self, forKey: .cityName)
        isTrainStation = try container.decodeIfPresent(Bool.self, forKey: .isTrainStation) ?? false
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

/// 내장 DB 의 노선 하나
struct BusRouteRecord: Hashable {
    let cityCode: String
    let routeId: String
    let routeNo: String
    let abrv: String
    let routeType: String
    let startName: String
    let endName: String
    let firstTime: String
    let lastTime: String
    let corp: String
    let term: String
    let length: String
}

final class BusDatabase {
    static let shared = BusDatabase()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.hotcha.busdatabase", qos: .userInitiated)
    private var cityNames: [String: String] = [:]
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private init() {
        guard let path = Bundle.main.path(forResource: "BusData", ofType: "sqlite") else { return }
        // 번들 파일은 쓸 수 없으니 읽기 전용 + immutable 로 연다.
        let uri =
            "file:\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)?immutable=1"
        if sqlite3_open_v2(uri, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) != SQLITE_OK {
            sqlite3_close(db)
            db = nil
            return
        }
        for row in rows("SELECT code, name FROM cities", []) {
            cityNames[row.text(0)] = row.text(1)
        }
    }

    // MARK: - 조회

    /// 도시 코드의 짧은 이름. 예: "1" → "서울", "37040" → "안동시"
    func cityName(for code: String) -> String {
        cityNames[code] ?? "알 수 없음"
    }

    /// 버스 번호로 노선을 찾는다. 내 위치에 가까운 노선이 먼저다 —
    /// 기점 · 종점이 내 주변 5km 안 → 내 주변 도시 → 그 밖 순이고, 각 무리 안에서는 정확히 일치 → 앞부분 일치 → 포함 순이다.
    /// 가까움은 기점 · 종점 중 가까운 쪽까지의 거리로 잰다. 내장 DB 에는 노선이 지나는 정류장이 없어 양 끝만 알 수 있다.
    func searchRoutes(_ text: String, near location: CLLocation? = nil, limit: Int = 120) async
        -> [BusRouteRecord]
    {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return await run {
            let nearby = self.routeCityCodes(near: location)
            let nearbyClause =
                nearby.isEmpty
                ? "0"
                : "city_code IN (\(nearby.map { _ in "?" }.joined(separator: ",")))"
            let sql = """
                SELECT city_code, route_id, route_no, abrv, route_type, start_name, end_name,
                       first_time, last_time, corp, term, length
                FROM routes
                WHERE route_no LIKE ? ESCAPE '\\'
                ORDER BY \(nearbyClause) DESC, (route_no = ?) DESC, (route_no LIKE ? ESCAPE '\\') DESC,
                         length(route_no), route_no, city_code
                LIMIT ?
                """
            let escaped = Self.escapeLike(query)
            let args: [Any] = ["%\(escaped)%"] + nearby + [query, "\(escaped)%", limit]
            var seen = Set<String>()
            let found = self.rows(sql, args).map { row in
                BusRouteRecord(
                    cityCode: row.text(0), routeId: row.text(1), routeNo: row.text(2), abrv: row.text(3),
                    routeType: row.text(4), startName: row.text(5), endName: row.text(6),
                    firstTime: row.text(7), lastTime: row.text(8), corp: row.text(9),
                    term: row.text(10), length: row.text(11)
                )
            }
            // TAGO 는 출발 시각만 다른 같은 노선을 여러 건으로 준다. 화면에서는 한 줄이면 된다.
            .filter { seen.insert("\($0.cityCode)|\($0.routeNo)|\($0.startName)|\($0.endName)").inserted }
            return self.sortedByNearness(found, query: query, near: location, nearbyCities: Set(nearby))
        }
    }

    /// 기점 · 종점이 내 주변 5km 안인 노선 → 내 주변 도시의 노선 → 그 밖 순으로 세운다.
    /// 각 무리 안에서는 일치 순위(정확히 · 앞부분 · 포함)가 먼저고, 첫 무리는 같은 순위끼리 가까운 순이다.
    private func sortedByNearness(
        _ routes: [BusRouteRecord], query: String, near location: CLLocation?, nearbyCities: Set<String>
    ) -> [BusRouteRecord] {
        let nearby = nearbyStopDistances(around: location)
        guard !nearby.isEmpty else { return routes }
        let lowered = query.lowercased()

        func rank(_ route: BusRouteRecord) -> Int {
            let number = route.routeNo.lowercased()
            if number == lowered { return 0 }
            return number.hasPrefix(lowered) ? 1 : 2
        }
        func terminalDistance(_ route: BusRouteRecord) -> Double? {
            [route.startName, route.endName]
                .compactMap { nearby["\(route.cityCode)|\(Self.normalized($0))"] }
                .min()
        }

        func group(_ route: BusRouteRecord, meters: Double?) -> Int {
            if meters != nil { return 0 }
            return nearbyCities.contains(route.cityCode) ? 1 : 2
        }

        struct Ranked {
            let offset: Int
            let route: BusRouteRecord
            let group: Int
            let rank: Int
            let meters: Double
        }

        return routes.enumerated()
            .map { item in
                let meters = terminalDistance(item.element)
                return Ranked(
                    offset: item.offset, route: item.element, group: group(item.element, meters: meters),
                    rank: rank(item.element), meters: meters ?? 0)
            }
            .sorted { a, b in
                if a.group != b.group { return a.group < b.group }
                if a.rank != b.rank { return a.rank < b.rank }
                if a.meters != b.meters { return a.meters < b.meters }
                return a.offset < b.offset
            }
            .map(\.route)
    }

    /// 내 주변 5km 안 정류장의 이름별 가장 가까운 거리(m). 열쇠는 "노선 도시 코드|이름" 이다.
    private func nearbyStopDistances(around location: CLLocation?) -> [String: Double] {
        guard let location else { return [:] }
        let c = location.coordinate
        let sql = """
            SELECT name, lat, lon, city_code FROM stops
            WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?
            """
        let box: [Any] = [c.latitude - 0.045, c.latitude + 0.045, c.longitude - 0.056, c.longitude + 0.056]
        var result: [String: Double] = [:]
        for row in rows(sql, box) {
            let meters = location.distance(from: CLLocation(latitude: row.double(1), longitude: row.double(2)))
            guard meters <= 5_000 else { continue }
            let key = "\(Self.routeCityCode(row.text(3)))|\(Self.normalized(row.text(0)))"
            result[key] = min(result[key] ?? .infinity, meters)
        }
        return result
    }

    /// 노선의 기점 · 종점 이름과 정류장 이름을 맞춰 보려고 띄어쓰기와 점을 뺀다.
    private static func normalized(_ name: String) -> String {
        name.filter { !$0.isWhitespace && $0 != "." && $0 != "·" }
    }

    /// 정류장 이름이나 정류장 번호로 찾는다. 위치를 알면 가까운 순으로 돌려준다.
    func searchStops(_ text: String, near location: CLLocation? = nil, limit: Int = 60) async
        -> [BusStopRecord]
    {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return await run {
            let escaped = Self.escapeLike(query)
            var order = "(name LIKE ? ESCAPE '\\') DESC"
            var args: [Any] = ["%\(escaped)%", query, "\(escaped)%"]
            if let location {
                order = Self.distanceOrder
                args = ["%\(escaped)%", query] + Self.distanceArgs(location.coordinate)
            } else {
                order += ", length(name), name"
            }
            let sql = """
                SELECT id, name, lat, lon, ars, city_code FROM stops
                WHERE name LIKE ? ESCAPE '\\' OR ars = ?
                ORDER BY \(order)
                LIMIT ?
                """
            // 같은 정류장이 서울·경기 양쪽 시스템에 따로 올라와 있는 경우가 있어 한 번만 보여준다.
            var seen = Set<String>()
            return self.rows(sql, args + [limit]).map(self.stop)
                .filter { seen.insert("\($0.name)|\($0.arsNumber)").inserted }
        }
    }

    /// 좌표 주변의 정류장을 가까운 순으로 돌려준다.
    func stops(near coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, limit: Int = 40) async
        -> [BusStopRecord]
    {
        await run {
            let latDelta = radius / 111_000
            let lonDelta = radius / (111_000 * max(cos(coordinate.latitude * .pi / 180), 0.1))
            let sql = """
                SELECT id, name, lat, lon, ars, city_code FROM stops
                WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?
                ORDER BY \(Self.distanceOrder)
                LIMIT ?
                """
            let args: [Any] =
                [
                    coordinate.latitude - latDelta, coordinate.latitude + latDelta,
                    coordinate.longitude - lonDelta, coordinate.longitude + lonDelta,
                ] + Self.distanceArgs(coordinate) + [limit]
            let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            var seen = Set<String>()
            return self.rows(sql, args).map(self.stop)
                .filter { $0.location.distance(from: center) <= radius }
                .filter { seen.insert("\($0.name)|\($0.arsNumber)").inserted }
        }
    }

    // MARK: - 내부

    // 위도 1도와 경도 1도의 길이 차이(한국 위도 기준 약 0.8배)만 보정한 근사 거리
    private static let distanceOrder = "((lat - ?) * (lat - ?) + (lon - ?) * (lon - ?) * 0.64)"

    private static func distanceArgs(_ c: CLLocationCoordinate2D) -> [Any] {
        [c.latitude, c.latitude, c.longitude, c.longitude]
    }

    private static func escapeLike(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private func stop(_ row: Row) -> BusStopRecord {
        BusStopRecord(
            id: row.text(0), name: row.text(1), latitude: row.double(2), longitude: row.double(3),
            arsNumber: row.text(4), cityName: cityName(for: row.text(5))
        )
    }

    /// 내 주변 5km 안 정류장들의 도시 코드를 노선 테이블 기준으로 바꿔 돌려준다.
    private func routeCityCodes(near location: CLLocation?) -> [String] {
        guard let c = location?.coordinate else { return [] }
        let sql = """
            SELECT DISTINCT city_code FROM stops
            WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?
            """
        return rows(sql, [c.latitude - 0.045, c.latitude + 0.045, c.longitude - 0.056, c.longitude + 0.056])
            .map { Self.routeCityCode($0.text(0)) }
    }

    /// 정류장 파일의 도시 코드를 노선 테이블의 도시 코드로 바꾼다.
    /// 정류장 파일은 서울이 11, 노선은 서울시 API 를 쓰는 1 이다. 나머지 도시는 같다.
    private static func routeCityCode(_ stopCityCode: String) -> String {
        stopCityCode == "11" ? BusAPI.seoulCityCode : stopCityCode
    }

    private func run<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            queue.async { continuation.resume(returning: work()) }
        }
    }

    private struct Row {
        let values: [Any?]
        func text(_ index: Int) -> String { values[index] as? String ?? "" }
        func double(_ index: Int) -> Double { values[index] as? Double ?? 0 }
    }

    private func rows(_ sql: String, _ args: [Any]) -> [Row] {
        guard let db else { return [] }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        for (offset, arg) in args.enumerated() {
            let index = Int32(offset + 1)
            switch arg {
            case let value as String: sqlite3_bind_text(statement, index, value, -1, transient)
            case let value as Double: sqlite3_bind_double(statement, index, value)
            case let value as Int: sqlite3_bind_int64(statement, index, Int64(value))
            default: sqlite3_bind_null(statement, index)
            }
        }

        var result: [Row] = []
        let columns = sqlite3_column_count(statement)
        while sqlite3_step(statement) == SQLITE_ROW {
            var values: [Any?] = []
            for column in 0..<columns {
                switch sqlite3_column_type(statement, column) {
                case SQLITE_FLOAT: values.append(sqlite3_column_double(statement, column))
                case SQLITE_INTEGER: values.append(Double(sqlite3_column_int64(statement, column)))
                case SQLITE_TEXT: values.append(String(cString: sqlite3_column_text(statement, column)))
                default: values.append(nil)
                }
            }
            result.append(Row(values: values))
        }
        return result
    }
}

extension Bus_info_seoul {
    /// 내장 DB 의 노선을 화면들이 쓰는 모델로 바꾼다. (저장소에 넣지 않는 임시 객체)
    convenience init(record: BusRouteRecord) {
        self.init(
            busRouteAbrv: record.abrv,
            busRouteId: record.routeId,
            busRouteNm: record.routeNo,
            corpNm: record.corp,
            stStationNm: record.startName,
            edStationNm: record.endName,
            firstBusTm: record.firstTime,
            firstLowTm: record.firstTime,
            lastBusTm: record.lastTime,
            lastBusYn: record.lastTime,
            lastLowTm: "",
            length: record.length,
            routeType: record.routeType,
            term: record.term,
            city_code: record.cityCode
        )
    }
}
