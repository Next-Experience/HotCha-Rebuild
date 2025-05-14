//
//  Usagehistorymodel.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import SwiftData
import Foundation

@Model
class Usage_history {
    var bus: Bus_info_seoul
    var route_id: String
    var city_code: String
    var destination_stop_id: String
    var destination_stop_name: String
    var bus_no: String
    var route_type: String
    var get_off_timestamp: Date
    var operator_name: String? = nil
    var operator_no: String? = nil
    var vehicle_no: String
    
    init(bus: Bus_info_seoul, route_id: String, city_code: String, destination_stop_id: String, destination_stop_name: String, bus_no: String, route_type: String, get_off_timestamp: Date, operator_name: String? = nil, operator_no: String? = nil, vehicle_no: String) {
        self.bus = bus
        self.route_id = route_id
        self.city_code = city_code
        self.destination_stop_id = destination_stop_id
        self.destination_stop_name = destination_stop_name
        self.bus_no = bus_no
        self.route_type = route_type
        self.get_off_timestamp = get_off_timestamp
        self.operator_name = operator_name
        self.operator_no = operator_no
        self.vehicle_no = vehicle_no
    }
}
