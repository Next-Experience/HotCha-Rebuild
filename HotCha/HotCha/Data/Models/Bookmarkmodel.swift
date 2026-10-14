//
//  Bookmarkmodel.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import SwiftData

@Model
class Bookmarkmodel: Identifiable {
    var bus: BusFavoriteHistory
    var route_id: String
    var city_code: String
    var destination_stop_id: String
    var destination_stop_name: String
    var bus_no: String
    var route_type: String
    var bookmark_label: String
    var bookmark_type: Int     // 0은 커스텀 1은 집 2는 회사
    /// "route"(버스 + 내릴 정류장) · "stop"(내릴 정류장만, 어느 버스든). 예전 즐겨찾기는 모두 버스다.
    var kind: String = "route"
    // 정류장 즐겨찾기만 쓴다. 정류장 알람은 좌표로 거리를 잰다.
    var stop_latitude: Double = 0
    var stop_longitude: Double = 0
    var stop_ars: String = ""
    var stop_city_name: String = ""

    init(bus: BusFavoriteHistory, route_id: String, city_code: String, destination_stop_id: String, destination_stop_name: String, bus_no: String, route_type: String, bookmark_label: String, bookmark_type: Int) {
        self.bus = bus
        self.route_id = route_id
        self.city_code = city_code
        self.destination_stop_id = destination_stop_id
        self.destination_stop_name = destination_stop_name
        self.bus_no = bus_no
        self.route_type = route_type
        self.bookmark_label = bookmark_label
        self.bookmark_type = bookmark_type
    }

    /// 정류장 즐겨찾기를 만든다. 노선 칸은 비워 둔다.
    convenience init(stop: BusStopRecord, label: String, type: Int) {
        self.init(
            bus: BusFavoriteHistory(
                busRouteAbrv: "", busRouteId: "", busRouteNm: "", corpNm: "", stStationNm: "", edStationNm: "",
                firstBusTm: "", firstLowTm: "", lastBusTm: "", lastBusYn: "", lastLowTm: "", length: "",
                routeType: "", term: "", city_code: ""),
            route_id: "", city_code: "", destination_stop_id: stop.id, destination_stop_name: stop.name,
            bus_no: "", route_type: "", bookmark_label: label, bookmark_type: type)
        kind = "stop"
        stop_latitude = stop.latitude
        stop_longitude = stop.longitude
        stop_ars = stop.arsNumber
        stop_city_name = stop.cityName
    }

    var isStop: Bool { kind == "stop" }

    /// 정류장 즐겨찾기의 정류장. 버스 즐겨찾기면 nil 이다.
    var stopRecord: BusStopRecord? {
        guard isStop else { return nil }
        return BusStopRecord(
            id: destination_stop_id, name: destination_stop_name, latitude: stop_latitude,
            longitude: stop_longitude, arsNumber: stop_ars, cityName: stop_city_name)
    }

    /// 목록의 설명 줄. "152번 · 미아초교" · "정류장 · 미아초교"
    var summary: String {
        isStop ? "정류장 · \(destination_stop_name)" : "\(bus_no)번 · \(destination_stop_name)"
    }
}
