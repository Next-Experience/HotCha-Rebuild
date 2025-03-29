//
//  FetchSeoulBusLocation.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//


import Foundation
// 서울 버스 위치를 가져오는 함수
func fetchSeoulBusLocation(busRouteId: String, completion: @escaping ([BusInfo]?, String?) -> Void) {

    if let apiKey = getAPIKey() {
        print("API Key: \(apiKey)")
        // 여기서 API 호출에 사용
    let urlString = "http://ws.bus.go.kr/api/rest/buspos/getBusPosByRtid?serviceKey=\(apiKey)&busRouteId=\(busRouteId)"
    
    guard let url = URL(string: urlString) else {
        completion(nil, "Invalid URL")
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, "데이터를 가져오는 데 실패했습니다: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            completion(nil, "No data received")
            return
        }
        
        let parser = BusInfoParser()
        parser.completionHandler = { busInfos in
            completion(busInfos, nil)
        }
        parser.parse(data: data)
    }.resume()
    
} else {
    print("API Key가 없습니다.")
}
}
