//
//  SeoulBusDatamodel.swift
//  HotCha
//
//  Created by 문재윤 on 3/29/25.
//

import SwiftData

@Model
class Bus_info_seoul: Identifiable {
    var busRouteAbrv: String
    var busRouteId: String
    var busRouteNm: String
    var corpNm: String
    var stStationNm: String
    var edStationNm: String
    var firstBusTm: String
    var firstLowTm: String
    var lastBusTm: String
    var lastBusYn: String
    var lastLowTm: String
    var length: String
    var routeType: String
    var term: String
    var city_code: String
    
    init(busRouteAbrv: String, busRouteId: String, busRouteNm: String, corpNm: String, stStationNm: String, edStationNm: String, firstBusTm: String, firstLowTm: String, lastBusTm: String, lastBusYn: String, lastLowTm: String, length: String, routeType: String, term: String, city_code: String) {
        self.busRouteAbrv = busRouteAbrv
        self.busRouteId = busRouteId
        self.busRouteNm = busRouteNm
        self.corpNm = corpNm
        self.stStationNm = stStationNm
        self.edStationNm = edStationNm
        self.firstBusTm = firstBusTm
        self.firstLowTm = firstLowTm
        self.lastBusTm = lastBusTm
        self.lastBusYn = lastBusYn
        self.lastLowTm = lastLowTm
        self.length = length
        self.routeType = routeType
        self.term = term
        self.city_code = city_code
    }
}

