//
//  BusAPI.swift
//  HotCha
//

import Foundation

/// 공공데이터포털 버스 API 공통 설정
enum BusAPI {
    /// 앱이 서울 노선을 구분하는 도시 코드. 서울은 TAGO 가 아니라 서울시 API 로 조회한다.
    static let seoulCityCode = "1"

    /// `Config/Secrets.xcconfig` 의 `API_KEY` (URL 인코딩된 서비스 키)
    static var serviceKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !key.isEmpty else {
            return nil
        }
        return key
    }

    /// 노선의 정류장 목록을 도시에 맞는 API 로 가져온다.
    static func fetchRouteStops(cityCode: String, routeId: String, completion: @escaping ([BusStop], String?) -> Void) {
        if cityCode == seoulCityCode {
            fetchBusStations(routeId: routeId, completion: completion)
        } else {
            fetchBusStation(cityCode: cityCode, routeId: routeId, completion: completion)
        }
    }
}
