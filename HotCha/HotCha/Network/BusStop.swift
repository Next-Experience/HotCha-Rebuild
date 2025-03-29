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
    var routeid: String
    var nodeid: String
    var nodenm: String
    var nodeno: Int?
    var nodeord: Int
    var gpslati: Double
    var gpslong: Double

    
    enum CodingKeys: String, CodingKey {
        case routeid, nodeid, nodenm, nodeno, nodeord, gpslati, gpslong
    }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        routeid = try container.decode(String.self, forKey: .routeid)
        nodeid = try container.decode(String.self, forKey: .nodeid)
        nodenm = try container.decode(String.self, forKey: .nodenm)
        
        // nodeno 처리
        if let nodenoString = try? container.decode(String.self, forKey: .nodeno),
           let nodenoInt = Int(nodenoString) {
            nodeno = nodenoInt
        } else {
            nodeno = try? container.decode(Int.self, forKey: .nodeno)
        }
        
        // nodeord 처리
        if let nodeordString = try? container.decode(String.self, forKey: .nodeord),
           let nodeordInt = Int(nodeordString) {
            nodeord = nodeordInt
        } else {
            nodeord = try container.decode(Int.self, forKey: .nodeord)
        }

        // gpslati 처리
        if let gpslatiString = try? container.decode(String.self, forKey: .gpslati),
           let gpslatiDouble = Double(gpslatiString) {
            gpslati = gpslatiDouble
        } else {
            gpslati = try container.decode(Double.self, forKey: .gpslati)
        }

        // gpslong 처리
        if let gpslongString = try? container.decode(String.self, forKey: .gpslong),
           let gpslongDouble = Double(gpslongString) {
            gpslong = gpslongDouble
        } else {
            gpslong = try container.decode(Double.self, forKey: .gpslong)
        }
        

    }
    
    // 기본 이니셜라이저 추가
    init(routeid: String, nodeid: String, nodenm: String, nodeno: Int?, nodeord: Int, gpslati: Double, gpslong: Double ) {
        self.routeid = routeid
        self.nodeid = nodeid
        self.nodenm = nodenm
        self.nodeno = nodeno
        self.nodeord = nodeord
        self.gpslati = gpslati
        self.gpslong = gpslong

    }
    
    // nodeid와 nodenm만으로 초기화하는 이니셜라이저
    init(nodeid: String, nodenm: String) {
        self.routeid = "알 수 없음"
        self.nodeid = nodeid
        self.nodenm = nodenm
        self.nodeno = nil
        self.nodeord = 0
        self.gpslati = 0.0
        self.gpslong = 0.0

    }
}
