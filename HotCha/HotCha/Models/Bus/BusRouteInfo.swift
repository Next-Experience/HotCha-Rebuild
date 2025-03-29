//
//  BusRouteInfo.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// BusRouteInfo.swift - 버스 노선 정보 모델
struct BusRouteInfo: Codable, Identifiable {
    let id = UUID()
    let routeId: String            // 노선 ID
    let routeName: String          // 노선명
    let routeTypeName: String      // 노선 유형
    let startStationName: String   // 기점명
    let endStationName: String     // 종점명
    let firstBusTime: String       // 첫차 시간
    let lastBusTime: String        // 막차 시간
    
    enum CodingKeys: String, CodingKey {
        case routeId = "routeid"
        case routeName = "routeno"
        case routeTypeName = "routetp"
        case startStationName = "startnodenm"
        case endStationName = "endnodenm"
        case firstBusTime = "startvehicletime"
        case lastBusTime = "endvehicletime"
    }
    
    // 디코딩 중 데이터 타입 변환을 위한 커스텀 이니셜라이저
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        routeId = try container.decode(String.self, forKey: .routeId)
        
        // routeno가 String 또는 Int로 올 수 있음
        if let routeNoString = try? container.decode(String.self, forKey: .routeName) {
            routeName = routeNoString
        } else if let routeNoInt = try? container.decode(Int.self, forKey: .routeName) {
            routeName = String(routeNoInt)
        } else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context(
                codingPath: [CodingKeys.routeName],
                debugDescription: "Unable to decode routeName"
            ))
        }
        
        routeTypeName = try container.decode(String.self, forKey: .routeTypeName)
        startStationName = try container.decode(String.self, forKey: .startStationName)
        endStationName = try container.decode(String.self, forKey: .endStationName)
        
        // firstBusTime이 String 또는 Int로 올 수 있음
        if let firstBusTimeString = try? container.decode(String.self, forKey: .firstBusTime) {
            firstBusTime = firstBusTimeString
        } else if let firstBusTimeInt = try? container.decode(Int.self, forKey: .firstBusTime) {
            firstBusTime = String(firstBusTimeInt)
        } else {
            firstBusTime = "정보 없음"
        }
        
        // lastBusTime이 String 또는 Int로 올 수 있음
        if let lastBusTimeString = try? container.decode(String.self, forKey: .lastBusTime) {
            lastBusTime = lastBusTimeString
        } else if let lastBusTimeInt = try? container.decode(Int.self, forKey: .lastBusTime) {
            lastBusTime = String(lastBusTimeInt)
        } else {
            lastBusTime = "정보 없음"
        }
    }
    
    // 테스트용 초기화 메서드
    init(routeId: String, routeName: String, routeTypeName: String, startStationName: String, endStationName: String, firstBusTime: String, lastBusTime: String) {
        self.routeId = routeId
        self.routeName = routeName
        self.routeTypeName = routeTypeName
        self.startStationName = startStationName
        self.endStationName = endStationName
        self.firstBusTime = firstBusTime
        self.lastBusTime = lastBusTime
    }
}
