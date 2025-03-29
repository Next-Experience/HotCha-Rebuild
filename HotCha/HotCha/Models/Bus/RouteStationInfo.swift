//
//  RouteStationInfo.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// RouteStationInfo.swift - 노선의 정류소 목록 정보
struct RouteStationInfo: Codable, Identifiable {
    let id = UUID()
    let routeId: String            // 노선 ID
    let routeName: String          // 노선명
    let stationId: String          // 정류소 ID
    let stationName: String        // 정류소명
    let stationSeq: Int            // 정류소 순번
    
    enum CodingKeys: String, CodingKey {
        case routeId = "routeid"
        case routeName = "routeno"
        case stationId = "nodeid"
        case stationName = "nodenm"
        case stationSeq = "nodeord"
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
            routeName = "알 수 없음"
        }
        
        stationId = try container.decode(String.self, forKey: .stationId)
        stationName = try container.decode(String.self, forKey: .stationName)
        
        // stationSeq가 String 또는 Int로 올 수 있음
        if let stationSeqString = try? container.decode(String.self, forKey: .stationSeq),
           let stationSeqInt = Int(stationSeqString) {
            stationSeq = stationSeqInt
        } else if let stationSeqInt = try? container.decode(Int.self, forKey: .stationSeq) {
            stationSeq = stationSeqInt
        } else {
            stationSeq = 0
        }
    }
    
    // 테스트용 초기화 메서드
    init(routeId: String, routeName: String, stationId: String, stationName: String, stationSeq: Int) {
        self.routeId = routeId
        self.routeName = routeName
        self.stationId = stationId
        self.stationName = stationName
        self.stationSeq = stationSeq
    }
}
