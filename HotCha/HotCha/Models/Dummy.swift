//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/24/25.
//

import Foundation

// MARK: - 버스 정보 (Bus_info)
struct Bus_info: Identifiable, Codable {
    var id = UUID()
    let bus_no: String
    let route_id: String
    let route_type: String
    let start_stop_name: String
    let end_stop_name: String
    let first_time: String
    let last_time: String
    let bus_interval: String
    let city_code: String
}

// MARK: - 정류장 정보 (Bus_stop)
struct Bus_stop: Identifiable, Codable {
    var id = UUID()
    let route_id: String
    let stop_id: String
    let stop_name: String
    let stop_x: Double
    let stop_y: Double
    let direction: String
}

// MARK: - 샘플 데이터
struct SampleData {
    static let bus_info_list: [Bus_info] = [
        Bus_info(bus_no: "101", route_id: "R101", route_type: "간선", start_stop_name: "서울역", end_stop_name: "강남역", first_time: "05:30", last_time: "23:50", bus_interval: "8", city_code: "1"),
        Bus_info(bus_no: "202", route_id: "R202", route_type: "지선", start_stop_name: "잠실역", end_stop_name: "홍대입구", first_time: "06:00", last_time: "00:30", bus_interval: "12", city_code: "1"),
        Bus_info(bus_no: "303", route_id: "R303", route_type: "광역", start_stop_name: "인천터미널", end_stop_name: "서울역", first_time: "05:00", last_time: "23:00", bus_interval: "15", city_code: "1"),
        Bus_info(bus_no: "404", route_id: "R404", route_type: "간선", start_stop_name: "노원역", end_stop_name: "서울대입구", first_time: "05:20", last_time: "00:10", bus_interval: "10", city_code: "1"),
        Bus_info(bus_no: "505", route_id: "R505", route_type: "공항", start_stop_name: "김포공항", end_stop_name: "강남역", first_time: "04:30", last_time: "22:30", bus_interval: "20", city_code: "1")
    ]

    static let bus_stops: [Bus_stop] = [
        // R101 노선 정류장 10개
        Bus_stop(route_id: "R101", stop_id: "S1011", stop_name: "서울역", stop_x: 126.9707, stop_y: 37.5563, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1012", stop_name: "남대문시장", stop_x: 126.9783, stop_y: 37.5602, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1013", stop_name: "시청역", stop_x: 126.9770, stop_y: 37.5660, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1014", stop_name: "을지로입구", stop_x: 126.9823, stop_y: 37.5661, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1015", stop_name: "종로3가", stop_x: 126.9910, stop_y: 37.5711, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1016", stop_name: "동대문", stop_x: 127.0092, stop_y: 37.5714, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1017", stop_name: "신설동", stop_x: 127.0194, stop_y: 37.5761, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1018", stop_name: "왕십리", stop_x: 127.0297, stop_y: 37.5611, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1019", stop_name: "한양대", stop_x: 127.0437, stop_y: 37.5553, direction: "0"),
        Bus_stop(route_id: "R101", stop_id: "S1020", stop_name: "강남역", stop_x: 127.0276, stop_y: 37.4979, direction: "0"),

        // R202 노선 정류장 10개
        Bus_stop(route_id: "R202", stop_id: "S2021", stop_name: "잠실역", stop_x: 127.1001, stop_y: 37.5133, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2022", stop_name: "종합운동장", stop_x: 127.0738, stop_y: 37.5108, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2023", stop_name: "삼성역", stop_x: 127.061, stop_y: 37.5088, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2024", stop_name: "선릉역", stop_x: 127.0473, stop_y: 37.5045, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2025", stop_name: "역삼역", stop_x: 127.0366, stop_y: 37.5006, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2026", stop_name: "강남역", stop_x: 127.0276, stop_y: 37.4979, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2027", stop_name: "교대역", stop_x: 127.0146, stop_y: 37.4932, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2028", stop_name: "서초역", stop_x: 127.007, stop_y: 37.4918, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2029", stop_name: "고속터미널", stop_x: 127.0025, stop_y: 37.5041, direction: "0"),
        Bus_stop(route_id: "R202", stop_id: "S2030", stop_name: "홍대입구", stop_x: 126.9237, stop_y: 37.5565, direction: "0")
    ]
}
