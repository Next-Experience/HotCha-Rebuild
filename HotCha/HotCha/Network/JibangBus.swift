
//
//  JibangBus.swift
//  HotCha
//
//  Created by 문재윤 on 5/20/25.
//

import Foundation

// 버스 데이터를 가져오는 함수
func fetchBusData(citycode: Int, routeNo: String, completion: @escaping ([Bus]) -> Void) {
    
    
    do {
        guard let serviceKey = getAPIKey() else {
            throw APIError.invalidAPI // API 키를 가져오지 못한 경우 예외 처리
        }
        
        let urlString = "http://apis.data.go.kr/1613000/BusRouteInfoInqireService/getRouteNoList?serviceKey=B%2FSwHGsQuvan%2F%2Fs6M6QvZooclQm9QpSHe%2BqbWjT4xPwDgHNXOES93T9i1%2BDKEJPWfCgcTf12X64bS9A42fFRkA%3D%3D&_type=json&cityCode=\(citycode)&routeNo=\(routeNo)&numOfRows=9999&pageNo=1"
        
        
        guard let url = URL(string: urlString) else {
            completion([]) // Return empty array for invalid URL
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([]) // Return empty array if no data
                return
            }
            
            // Try to decode as BusResponse first
            do {
                let response = try JSONDecoder().decode(BusResponse.self, from: data)
                if let items = response.response.body.items?.item {
                    DispatchQueue.main.async {
                        completion(items) // Return array of Bus objects
                    }
                    return // Exit the function after a successful completion
                }
            } catch {
                print("Array decoding failed: \(error)")
            }
            
            // If array decoding failed, try to decode as BusResponsenotarray
            do {
                let singleObjectResponse = try JSONDecoder().decode(BusResponsenotarray.self, from: data)
                if let singleBus = singleObjectResponse.response.body.items?.item {
                    DispatchQueue.main.async {
                        print("한개") // Single bus object found
                        completion([singleBus]) // Return an array containing the single Bus object
                    }
                    return // Exit the function after a successful completion
                }
            } catch {
                print("Single object decoding failed: \(error)")
            }
            
            // If both decodings failed
            DispatchQueue.main.async {
                completion([]) // Return empty array if no items found in both attempts
            }
        }.resume() // Start the data task
    } catch {
        print("API serviceKey Error")
    }
}


import Foundation

// 버스 정보를 위한 모델
struct Bus: Codable, Identifiable {
    let id = UUID() // 각 버스 객체에 대한 고유 ID
    let routeno: String // 노선 번호
    let routeid: String // 노선 ID
    let startnodenm: String // 출발 정류장 이름
    let endnodenm: String // 도착 정류장 이름
    let startvehicletime: String // 출발 시간
    let endvehicletime: String // 도착 시간
    let routetp: String // 노선 타입
    
    enum CodingKeys: String, CodingKey {
        case routeno, routeid, startnodenm, endnodenm, startvehicletime, endvehicletime, routetp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // routeno가 Int 또는 String인 경우를 처리
        if let routenoInt = try? container.decode(Int.self, forKey: .routeno) {
            routeno = String(routenoInt) // Int를 String으로 변환
        } else {
            routeno = (try? container.decode(String.self, forKey: .routeno)) ?? "알 수 없음" // String으로 디코딩 또는 기본값
        }
        
        // startvehicletime 처리
        if let startvehicletimeInt = try? container.decode(Int.self, forKey: .startvehicletime) {
            startvehicletime = String(startvehicletimeInt) // Int를 String으로 변환
        } else {
            startvehicletime = (try? container.decode(String.self, forKey: .startvehicletime)) ?? "알 수 없음" // 기본값
        }
        
        // endvehicletime 처리
        if let endvehicletimeInt = try? container.decode(Int.self, forKey: .endvehicletime) {
            endvehicletime = String(endvehicletimeInt) // Int를 String으로 변환
        } else {
            endvehicletime = (try? container.decode(String.self, forKey: .endvehicletime)) ?? "알 수 없음" // 기본값
        }
        
        routeid = (try? container.decode(String.self, forKey: .routeid)) ?? "알 수 없음"
        startnodenm = (try? container.decode(String.self, forKey: .startnodenm)) ?? "알 수 없음"
        endnodenm = (try? container.decode(String.self, forKey: .endnodenm)) ?? "알 수 없음"
        routetp = (try? container.decode(String.self, forKey: .routetp)) ?? "알 수 없음"
    }
    
    // 사용자 정의 이니셜라이저
        init(
            routeno: String = "알 수 없음",
            routeid: String = "알 수 없음",
            startnodenm: String = "알 수 없음",
            endnodenm: String = "알 수 없음",
            startvehicletime: String = "알 수 없음",
            endvehicletime: String = "알 수 없음",
            routetp: String = "알 수 없음"
        ) {
            self.routeno = routeno
            self.routeid = routeid
            self.startnodenm = startnodenm
            self.endnodenm = endnodenm
            self.startvehicletime = startvehicletime
            self.endvehicletime = endvehicletime
            self.routetp = routetp
        }

}



// API 응답을 위한 모델
struct BusResponse: Codable {
    let response: ResponseBody
    
    struct ResponseBody: Codable {
        let body: Body
        
        struct Body: Codable {
            let items: Items?
            
            struct Items: Codable {
                let item: [Bus]? // Bus 객체 배열
            }
        }
    }
}

// API 응답을 위한 모델
struct BusResponsenotarray: Codable {
    let response: ResponseBody
    
    struct ResponseBody: Codable {
        let body: Body
        
        struct Body: Codable {
            let items: Items?
            
            struct Items: Codable {
                let item: Bus? // Bus 객체 배열
            }
        }
    }
}
import Foundation

enum APIError: Error {
    case invalidAPI
    case invalidURL
    case requestFailed(statusCode: Int)
    case dataLoadingError(underlyingError: Error)
    case decodingError(underlyingError: Error)
}
