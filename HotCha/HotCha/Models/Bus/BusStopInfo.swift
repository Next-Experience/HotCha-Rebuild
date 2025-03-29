//
//  BusStopInfo.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// BusStopInfo.swift - 버스 정류소 정보 모델
struct BusStopInfo: Codable, Identifiable {
    let id = UUID()
    let stationId: String          // 정류소 ID
    let stationName: String        // 정류소 명
    let regionName: String         // 지역명
    let mobileNo: String?          // 정류소 고유번호
    let latitude: Double           // 위도
    let longitude: Double          // 경도
    
    enum CodingKeys: String, CodingKey {
        case stationId = "nodeid"
        case stationName = "nodenm"
        case regionName = "nodeno"
        case mobileNo = "gpslati"
        case latitude = "gpslong"
        case longitude = "nodeord"
    }
    
    // 디코딩 중 데이터 타입 변환을 위한 커스텀 이니셜라이저
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        stationId = try container.decode(String.self, forKey: .stationId)
        stationName = try container.decode(String.self, forKey: .stationName)
        
        // regionName이 문자열 또는 숫자로 올 수 있음
        if let regionNameStr = try? container.decode(String.self, forKey: .regionName) {
            regionName = regionNameStr
        } else if let regionNameInt = try? container.decode(Int.self, forKey: .regionName) {
            regionName = String(regionNameInt)
        } else {
            regionName = "알 수 없음"
        }
        
        mobileNo = try? container.decode(String.self, forKey: .mobileNo)
        
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
    init(stationId: String, stationName: String, regionName: String, mobileNo: String?, latitude: Double, longitude: Double) {
        self.stationId = stationId
        self.stationName = stationName
        self.regionName = regionName
        self.mobileNo = mobileNo
        self.latitude = latitude
        self.longitude = longitude
    }
}
