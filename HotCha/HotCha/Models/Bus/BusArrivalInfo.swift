//
//  BusArrivalInfo.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// BusArrivalInfo.swift - 버스 도착 정보 모델
struct BusArrivalInfo: Codable, Identifiable {
    let id = UUID()
    let routeId: String            // 노선 ID
    let routeName: String          // 노선명
    let stationId: String          // 정류소 ID
    let stationName: String        // 정류소 명
    let predictTime1: Int          // 첫번째 버스 도착 예정 시간(분)
    let predictTime2: Int?         // 두번째 버스 도착 예정 시간(분)
    let locationNo1: Int?          // 첫번째 버스 현재 위치(몇 번째 정류소)
    let locationNo2: Int?          // 두번째 버스 현재 위치(몇 번째 정류소)
    
    enum CodingKeys: String, CodingKey {
        case routeId = "routeid"
        case routeName = "routeno"
        case stationId = "nodeid"
        case stationName = "nodenm"
        case predictTime1 = "arrtime"
        case predictTime2 = "arrtime2"
        case locationNo1 = "nodeno"
        case locationNo2 = "nodeno2"
    }
    
    // 테스트용 초기화 메서드
    init(routeId: String, routeName: String, stationId: String, stationName: String, predictTime1: Int, predictTime2: Int? = nil, locationNo1: Int? = nil, locationNo2: Int? = nil) {
        self.routeId = routeId
        self.routeName = routeName
        self.stationId = stationId
        self.stationName = stationName
        self.predictTime1 = predictTime1
        self.predictTime2 = predictTime2
        self.locationNo1 = locationNo1
        self.locationNo2 = locationNo2
    }
}

