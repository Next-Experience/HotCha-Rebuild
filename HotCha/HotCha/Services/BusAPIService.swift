//
//  BusAPIService.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

// BusAPIService.swift
import Foundation
import Combine

class BusAPIService {
    // 싱글톤 인스턴스
    static let shared = BusAPIService()
    private init() {}
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
    
    // 기본 API 호출 메서드
    private func fetchData<T: Codable>(urlString: String) -> AnyPublisher<[T], NetworkError> {
        // 요청 URL 로깅
        print("=== API REQUEST ===")
        print("Requesting API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { error -> NetworkError in
                print("Network failure: \(error.localizedDescription)")
                return NetworkError.networkFailure(error)
            }
            .flatMap { data, response -> AnyPublisher<[T], NetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
                }
                
                // 응답 상태 코드 로깅
                print("=== API RESPONSE ===")
                print("API Response Status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
                }
                
                // 원시 응답 데이터 상세 로깅
                print("Raw API Response:")
                if let responseString = String(data: data, encoding: .utf8) {
                    print(responseString)
                } else {
                    print("Unable to decode response to string")
                }
                
                return Just(data)
                    .decode(type: APIResponse<T>.self, decoder: self.decoder)
                    .mapError { error -> NetworkError in
                        print("=== DECODING ERROR ===")
                        print("Error: \(error)")
                        print("Error description: \(error.localizedDescription)")
                        
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .typeMismatch(let type, let context):
                                print("Type mismatch: expected \(type), context: \(context)")
                            case .valueNotFound(let type, let context):
                                print("Value not found: \(type), context: \(context)")
                            case .keyNotFound(let key, let context):
                                print("Key not found: \(key), context: \(context)")
                            case .dataCorrupted(let context):
                                print("Data corrupted: \(context)")
                            @unknown default:
                                print("Unknown decoding error")
                            }
                        }
                        return NetworkError.decodingError(error)
                    }
                    .flatMap { response -> AnyPublisher<[T], NetworkError> in
                        // API 응답 코드 확인
                        if response.response.header.resultCode != "00" {
                            print("API Error Code: \(response.response.header.resultCode), Message: \(response.response.header.resultMsg)")
                            return Fail(error: NetworkError.apiError(
                                response.response.header.resultCode,
                                response.response.header.resultMsg
                            )).eraseToAnyPublisher()
                        }
                        
                        // 수정된 응답 데이터 확인 부분
                        if let body = response.response.body,
                           let items = body.items,
                           let itemArray = items.item {
                            if itemArray.isEmpty {
                                print("Item array is empty")
                            } else {
                                print("Successfully decoded \(itemArray.count) items")
                            }
                            return Just(itemArray).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                        } else {
                            print("Empty response structure")
                            return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 버스 도착 정보 API
    
    /// 정류소 ID로 버스 도착 정보 조회
    func getBusArrivalInfo(stationId: String, cityCode: String) -> AnyPublisher<[BusArrivalInfo], NetworkError> {
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busArrival)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&nodeId=\(stationId)&numOfRows=100&_type=json"
        return fetchData(urlString: urlString)
    }
    
    // MARK: - 버스 정류소 정보 API
    
    /// 지역코드와 정류소 이름으로 정류소 정보 조회
    func getBusStopInfo(stationName: String, cityCode: String) -> AnyPublisher<[BusStopInfo], NetworkError> {
        // URL에 한글이 포함될 수 있으므로 인코딩 처리
        let encodedStationName = stationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? stationName
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busStop)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&nodeNm=\(encodedStationName)&numOfRows=100&_type=json"
        return fetchData(urlString: urlString)
    }
    
    // MARK: - 버스 위치 정보 API
    
    /// 노선 ID로 버스 위치 정보 조회
    func getBusLocationInfo(routeId: String, cityCode: String) -> AnyPublisher<[BusLocationInfo], NetworkError> {
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busLocation)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeId=\(routeId)&numOfRows=100&_type=json"
        return fetchData(urlString: urlString)
    }
    
    // MARK: - 버스 노선 정보 API
    
    /// 버스 번호로 노선 정보 조회
    func getBusRouteInfo(routeName: String, cityCode: String) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busRoute)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        return fetchData(urlString: urlString)
    }
    
    // MARK: - 버스 노선별 정류소 목록 API
    
    /// 노선 ID로 정류소 목록 조회
    func getRouteStationList(routeId: String, cityCode: String) -> AnyPublisher<[RouteStationInfo], NetworkError> {
        let urlString = "\(Constants.API.baseURL)\(Constants.API.routeStations)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeId=\(routeId)&numOfRows=300&_type=json"
        return fetchData(urlString: urlString)
    }
}
