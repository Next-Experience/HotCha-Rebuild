//
//  Bookmarkmodel.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import SwiftData

@Model
class Bookmarkmodel: Identifiable {
    var bus: Bus_info_seoul
    var route_id: String
    var city_code: String
    var destination_stop_id: String
    var destination_stop_name: String
    var bus_no: String
    var route_type: String
    var bookmark_label: String
    var bookmark_type: Int     // 0은 커스텀 1은 집 2는 회사

    init(bus: Bus_info_seoul, route_id: String, city_code: String, destination_stop_id: String, destination_stop_name: String, bus_no: String, route_type: String, bookmark_label: String, bookmark_type: Int) {
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
}
