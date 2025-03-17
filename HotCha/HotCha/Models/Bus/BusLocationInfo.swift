//
//  BusLocationInfo.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// BusLocationInfo.swift - 버스 위치 정보 모델
struct BusLocationInfo: Codable, Identifiable {
    let id = UUID()
    let routeId: String            // 노선 ID
    let routeName: String          // 노선명
    let vehicleId: String          // 차량 ID
    let stationId: String?         // 현재/최근 정류소 ID
    let stationSeq: Int            // 정류소 순번
    let stationName: String?       // 현재/최근 정류소명
    let latitude: Double           // 위도
    let longitude: Double          // 경도
    
    enum CodingKeys: String, CodingKey {
        case routeId = "routeid"
        case routeName = "routeno"
        case vehicleId = "vehicleno"
        case stationId = "nodeid"
        case stationSeq = "nodeord"
        case stationName = "nodenm"
        case latitude = "gpslati"
        case longitude = "gpslong"
    }
    
    // 디코딩 중 데이터 타입 변환을 위한 커스텀 이니셜라이저
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        routeId = try container.decode(String.self, forKey: .routeId)
        
        // routeno가 String 또는 Int로 올 수 있음
        if let routeNoStr = try? container.decode(String.self, forKey: .routeName) {
            routeName = routeNoStr
        } else if let routeNoInt = try? container.decode(Int.self, forKey: .routeName) {
            routeName = String(routeNoInt)
        } else {
            routeName = "알 수 없음"
        }
        
        vehicleId = try container.decode(String.self, forKey: .vehicleId)
        stationId = try? container.decode(String.self, forKey: .stationId)
        
        // stationSeq가 String 또는 Int로 올 수 있음
        if let stationSeqStr = try? container.decode(String.self, forKey: .stationSeq),
           let stationSeqInt = Int(stationSeqStr) {
            stationSeq = stationSeqInt
        } else if let stationSeqInt = try? container.decode(Int.self, forKey: .stationSeq) {
            stationSeq = stationSeqInt
        } else {
            stationSeq = 0
        }
        
        stationName = try? container.decode(String.self, forKey: .stationName)
        
        // 위도와 경도 처리
        if let latitudeStr = try? container.decode(String.self, forKey: .latitude),
           let latitudeDouble = Double(latitudeStr) {
            latitude = latitudeDouble
        } else if let latitudeDouble = try? container.decode(Double.self, forKey: .latitude) {
            latitude = latitudeDouble
        } else {
            latitude = 0.0
        }
        
        if let longitudeStr = try? container.decode(String.self, forKey: .longitude),
           let longitudeDouble = Double(longitudeStr) {
            longitude = longitudeDouble
        } else if let longitudeDouble = try? container.decode(Double.self, forKey: .longitude) {
            longitude = longitudeDouble
        } else {
            longitude = 0.0
        }
    }
    
    // 테스트용 초기화 메서드
    init(routeId: String, routeName: String, vehicleId: String, stationId: String?, stationSeq: Int, stationName: String?, latitude: Double, longitude: Double) {
        self.routeId = routeId
        self.routeName = routeName
        self.vehicleId = vehicleId
        self.stationId = stationId
        self.stationSeq = stationSeq
        self.stationName = stationName
        self.latitude = latitude
        self.longitude = longitude
    }
}
