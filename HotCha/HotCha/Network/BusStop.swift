//
//  BusStop.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//


// 이것도 전국 버스 스탑 json받아오는 구조

import Foundation

// MARK: - Items
struct BusStopList_Items: Codable {
    let item: [BusStop]
}

// MARK: - BusStop
struct BusStop: Codable, Identifiable, Hashable {
    var id = UUID() // 각 버스 객체에 대한 고유 ID
    var busRouteId: String         // 노선ID
    var busRouteNm: String         // 노선명
    var seq: Int                   // 순번
    var station: String            // 정류소 ID
    var stationNm: String          // 정류소명
    var gpsX: Double               // 좌표 X (WGS84)
    var gpsY: Double               // 좌표 Y (WGS84)
    var stationNo: Int             // 정류소 고유 번호
    
    
    // 옵션 항목들
    var direction: String?          // 진행방향
    var section: String?            // 구간ID
    var routeType: Int?             // 노선유형 (3:간선, 4:지선, 5:순환, 6:광역)
    var beginTm: String?            // 첫차시간 (예: "20230402123000")
    var lastTm: String?             // 막차시간
    var posX: Double?              // 좌표 X (GRS80)
    var posY: Double?              // 좌표 Y (GRS80)
    var arsId: Int?                // 정류소 번호
    var transYn: String?           // 회차지 여부 ("Y"/"N")
    var trnstnid: String?          // 회차지 ID
    var sectSpd: Int?              // 구간속도
    var fullSectDist: Int?         // 구간거리
    
    
    // 앱 내부 로직에서 필요한 변수
    var busStopCase: BusStopElementCase = [.ableStop] // 정류장 종류
    var alarmStation: Bool = false // 알람정류장
    var arrivalStation: Bool = false // 도착정류장
    var filtered: Bool = false
    var isFirstStop: Bool = false // 노선의 첫번째 정류장
    var isLastStop: Bool = false // 노선의 마지막 정류장
    
    //enum CodingKeys: String, CodingKey {
    //    case routeid, nodeid, nodenm, nodeno, nodeord, gpslati, gpslong
    //}
    
    enum CodingKeys: String, CodingKey {
        case busRouteId, busRouteNm, seq,  station, stationNm, gpsX, gpsY, stationNo
        case routeType, direction, beginTm, lastTm, section, posX, posY, arsId, transYn, trnstnid, sectSpd, fullSectDist
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 필수 항목
        busRouteId = try container.decode(String.self, forKey: .busRouteId)
        busRouteNm = try container.decode(String.self, forKey: .busRouteNm)
        seq = try container.decode(Int.self, forKey: .seq)
        station = try container.decode(String.self, forKey: .station)
        stationNm = try container.decode(String.self, forKey: .stationNm)
        
        // gpsX
        if let gpsXString = try? container.decode(String.self, forKey: .gpsX),
           let gpsXDouble = Double(gpsXString) {
            gpsX = gpsXDouble
        } else {
            gpsX = try container.decode(Double.self, forKey: .gpsX)
        }
        
        // gpsY
        if let gpsYString = try? container.decode(String.self, forKey: .gpsY),
           let gpsYDouble = Double(gpsYString) {
            gpsY = gpsYDouble
        } else {
            gpsY = try container.decode(Double.self, forKey: .gpsY)
        }
        
        // stationNo
        if let stationNoString = try? container.decode(String.self, forKey: .stationNo),
           let stationNoInt = Int(stationNoString) {
            stationNo = stationNoInt
        } else {
            stationNo = try container.decode(Int.self, forKey: .stationNo)
        }
        
        // 선택적 항목
        direction = try? container.decodeIfPresent(String.self, forKey: .direction)
        section = try? container.decodeIfPresent(String.self, forKey: .section)
        
        if let routeTypeString = try? container.decode(String.self, forKey: .routeType),
           let routeTypeInt = Int(routeTypeString) {
            routeType = routeTypeInt
        } else {
            routeType = try? container.decodeIfPresent(Int.self, forKey: .routeType)
        }
        
        beginTm = try? container.decodeIfPresent(String.self, forKey: .beginTm)
        lastTm = try? container.decodeIfPresent(String.self, forKey: .lastTm)
        posX = try? container.decodeIfPresent(Double.self, forKey: .posX)
        posY = try? container.decodeIfPresent(Double.self, forKey: .posY)
        arsId = try? container.decodeIfPresent(Int.self, forKey: .arsId)
        transYn = try? container.decodeIfPresent(String.self, forKey: .transYn)
        trnstnid = try? container.decodeIfPresent(String.self, forKey: .trnstnid)
        sectSpd = try? container.decodeIfPresent(Int.self, forKey: .sectSpd)
        fullSectDist = try? container.decodeIfPresent(Int.self, forKey: .fullSectDist)
    }
    
    // 기본 이니셜라이저 추가
    init(
        busRouteId: String,
        busRouteNm: String,
        seq: Int,
        station: String,
        stationNm: String,
        gpsX: Double,
        gpsY: Double,
        stationNo: Int
    ) {
        self.busRouteId = busRouteId
        self.busRouteNm = busRouteNm
        self.seq = seq
        self.station = station
        self.stationNm = stationNm
        self.gpsX = gpsX
        self.gpsY = gpsY
        self.stationNo = stationNo
        
        // 옵션 값은 기본 nil
        self.direction = nil
        self.section = nil
        self.routeType = nil
        self.beginTm = nil
        self.lastTm = nil
        self.posX = nil
        self.posY = nil
        self.arsId = nil
        self.transYn = nil
        self.trnstnid = nil
        self.sectSpd = nil
        self.fullSectDist = nil
        
        // 앱 내부 로직 값 초기화
//        self.busStopCase = .ableStop
        self.alarmStation = false
        self.arrivalStation = false
        self.filtered = false
        self.isFirstStop = false
        self.isLastStop = false
    }
    
    
    // nodeid와 nodenm만으로 초기화하는 이니셜라이저
    init(station: String, stationNm: String) {
        self.busRouteId = "알 수 없음"
        self.busRouteNm = "알 수 없음"
        self.seq = 0
        self.station = station
        self.stationNm = stationNm
        self.gpsX = 0.0
        self.gpsY = 0.0
        self.stationNo = 0
        
        self.direction = nil
        self.section = nil
        self.routeType = nil
        self.beginTm = nil
        self.lastTm = nil
        self.posX = nil
        self.posY = nil
        self.arsId = nil
        self.transYn = nil
        self.trnstnid = nil
        self.sectSpd = nil
        self.fullSectDist = nil
        
//        self.busStopCase = .ableStop
        self.alarmStation = false
        self.arrivalStation = false
        self.filtered = false
        self.isFirstStop = false
        self.isLastStop = false
    }
}
