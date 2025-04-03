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
                    
                    // XML 응답 확인
                    if responseString.hasPrefix("<") {
                        print("Response is XML, not JSON. Cannot decode.")
                        return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                    }
                } else {
                    print("Unable to decode response to string")
                }
                
                // JSON 구조 확인을 위한 추가 로깅
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("JSON Structure:")
                    print(json)
                }
                
                return Just(data)
                    .tryMap { data -> Data in
                        // 응답이 비어있는지 확인
                        guard !data.isEmpty else {
                            throw NetworkError.emptyResponse
                        }
                        return data
                    }
                    .tryMap { data -> APIResponse<T> in
                        do {
                            return try self.decoder.decode(APIResponse<T>.self, from: data)
                        } catch {
                            print("=== DECODING ERROR ===")
                            print("Error: \(error)")
                            
                            // 일반적인 디코딩에 실패한 경우 임시 모델로 시도 (5자리 지역코드용)
                            if let altResponse = try? self.decoder.decode(AlternativeAPIResponse<T>.self, from: data) {
                                // 대체 응답 구조를 표준 구조로 변환
                                return APIResponse(alternativeResponse: altResponse)
                            }
                            
                            // 모든 디코딩 시도 실패
                            throw error
                        }
                    }
                    .mapError { error -> NetworkError in
                        if let networkError = error as? NetworkError {
                            return networkError
                        }
                        
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
                        
                        // 응답 데이터 확인
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
    
    // 버스 번호로 노선 정보 조회 (수정된 버전 - 2글자 및 5글자 모두 지원)
    func getBusRouteInfo(routeName: String, cityCode: String) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        
        // 우선 2글자 cityCode로 시도
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busRoute)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        
        return fetchData(urlString: urlString)
            .catch { error -> AnyPublisher<[BusRouteInfo], NetworkError> in
                // 첫 번째 요청 실패 시 다른 방법으로 시도
                
                // 5글자 코드이면 2글자로 변환하여 시도
                if cityCode.count > 2 {
                    let shorterCode = String(cityCode.prefix(2))
                    let fallbackUrlString = "\(Constants.API.baseURL)\(Constants.API.busRoute)?serviceKey=\(Constants.apiKey)&cityCode=\(shorterCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
                    return self.fetchData(urlString: fallbackUrlString)
                }
                
                // 실패하면 원래 오류 반환
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 버스 노선별 정류소 목록 API
    
    /// 노선 ID로 정류소 목록 조회
    func getRouteStationList(routeId: String, cityCode: String) -> AnyPublisher<[RouteStationInfo], NetworkError> {
        let urlString = "\(Constants.API.baseURL)\(Constants.API.routeStations)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeId=\(routeId)&numOfRows=300&_type=json"
        return fetchData(urlString: urlString)
    }
}

// 대체 API 응답 구조 (5자리 지역코드용)
struct AlternativeAPIResponse<T: Codable>: Codable {
    let result: AlternativeResponseBody
    
    struct AlternativeResponseBody: Codable {
        let status: String
        let message: String
        let data: AlternativeData?
        
        struct AlternativeData: Codable {
            let list: [T]?
            let totalCount: Int?
        }
    }
}

// 확장: 대체 응답 구조를 표준 구조로 변환
extension APIResponse {
    init(alternativeResponse: AlternativeAPIResponse<T>) {
        let header = ResponseBody.Header(
            resultCode: alternativeResponse.result.status == "SUCCESS" ? "00" : "01",
            resultMsg: alternativeResponse.result.message
        )
        
        var body: ResponseBody.Body? = nil
        if let data = alternativeResponse.result.data {
            let items = ResponseBody.Body.Items(item: data.list ?? [])
            body = ResponseBody.Body(
                items: items,
                numOfRows: data.list?.count ?? 0,
                pageNo: 1,
                totalCount: data.totalCount ?? 0
            )
        }
        
        self.response = ResponseBody(header: header, body: body)
    }
}

// Helper extension for String to Int conversion
extension StringProtocol {
    var int: Int? {
        return Int(self)
    }
}

// 임시 대체 솔루션: JSON 디코딩 대신 수동 파싱
extension BusAPIService {
    
    // 수동 JSON 파싱을 통한 버스 노선 정보 조회
    func getBusRouteInfoRobust(routeName: String, cityCode: String) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        
        // 지역코드 처리 (2자리/5자리 모두 시도)
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busRoute)?serviceKey=\(Constants.apiKey)&cityCode=\(cityCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        
        print("API 요청: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .mapError { NetworkError.networkFailure($0) }
            .flatMap { data -> AnyPublisher<[BusRouteInfo], NetworkError> in
                // 응답 로깅
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw API Response: \(responseString)")
                }
                
                // 수동 파싱 시도
                return self.parseRouteInfoManually(from: data)
                    .catch { error -> AnyPublisher<[BusRouteInfo], NetworkError> in
                        // 첫 번째 시도 실패 시 2자리 코드로 재시도 (5자리인 경우)
                        if cityCode.count > 2, let prefixCode = cityCode.prefix(2).int {
                            print("5자리 코드 실패, 2자리 코드로 재시도: \(prefixCode)")
                            return self.tryAlternativeRequest(routeName: routeName, cityCode: String(prefixCode))
                        }
                        // 두 번째 시도: 다른 parameter 이름으로 시도
                        return self.tryAlternativeRequest(routeName: routeName, cityCode: cityCode)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // 대체 요청 시도
    private func tryAlternativeRequest(routeName: String, cityCode: String) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        
        // 다른 파라미터 이름으로 시도 (cityCode -> areaCode)
        let urlString = "\(Constants.API.baseURL)\(Constants.API.busRoute)?serviceKey=\(Constants.apiKey)&areaCode=\(cityCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        
        print("대체 API 요청: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .mapError { NetworkError.networkFailure($0) }
            .flatMap { data -> AnyPublisher<[BusRouteInfo], NetworkError> in
                if let responseString = String(data: data, encoding: .utf8) {
                    print("대체 API 응답: \(responseString)")
                }
                return self.parseRouteInfoManually(from: data)
            }
            .eraseToAnyPublisher()
    }
    
    // 수동 JSON 파싱 (최대한 유연하게)
    private func parseRouteInfoManually(from data: Data) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        do {
            // 1. JSON 파싱
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return Fail(error: NetworkError.invalidData).eraseToAnyPublisher()
            }
            
            print("JSON 구조: \(json.keys)")
            
            // 2. 표준 응답 구조 시도 ("response" > "body" > "items" > "item")
            if let response = json["response"] as? [String: Any],
               let body = response["body"] as? [String: Any],
               let items = body["items"] as? [String: Any],
               let itemArray = items["item"] as? [[String: Any]] {
                
                let routes = itemArray.compactMap { self.createBusRouteInfo(from: $0) }
                print("파싱 성공: \(routes.count)개 버스 노선")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            
            // 3. 대체 응답 구조 시도 #1 ("result" > "data" > "list")
            if let result = json["result"] as? [String: Any],
               let data = result["data"] as? [String: Any],
               let list = data["list"] as? [[String: Any]] {
                
                let routes = list.compactMap { self.createBusRouteInfo(from: $0) }
                print("대체 파싱 #1 성공: \(routes.count)개 버스 노선")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            
            // 4. 대체 응답 구조 시도 #2 (직접 "items" > "item")
            if let items = json["items"] as? [String: Any],
               let itemArray = items["item"] as? [[String: Any]] {
                
                let routes = itemArray.compactMap { self.createBusRouteInfo(from: $0) }
                print("대체 파싱 #2 성공: \(routes.count)개 버스 노선")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            
            // 5. 대체 응답 구조 시도 #3 (직접 "item" 배열)
            if let itemArray = json["item"] as? [[String: Any]] {
                let routes = itemArray.compactMap { self.createBusRouteInfo(from: $0) }
                print("대체 파싱 #3 성공: \(routes.count)개 버스 노선")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            
            // 6. XML 응답 확인
            if let dataString = String(data: data, encoding: .utf8), dataString.hasPrefix("<") {
                print("XML 응답이 감지되었습니다. JSON이 아닙니다.")
                return Fail(error: NetworkError.invalidData).eraseToAnyPublisher()
            }
            
            print("알 수 없는 JSON 구조: \(json)")
            return Fail(error: NetworkError.invalidData).eraseToAnyPublisher()
            
        } catch {
            print("JSON 파싱 오류: \(error)")
            return Fail(error: NetworkError.decodingError(error)).eraseToAnyPublisher()
        }
    }
    
    // Dictionary에서 BusRouteInfo 생성 (최대한 안전하게)
    private func createBusRouteInfo(from dict: [String: Any]) -> BusRouteInfo? {
        // 필수 필드가 없을 경우 기본값으로 대체
        
        // routeId (routeid 또는 ROUTE_ID 등 다양한 키를 시도)
        let routeId = findStringValue(in: dict, candidates: ["routeid", "ROUTE_ID", "routeId", "route_id"]) ?? "알 수 없음"
        
        // routeName
        let routeName = findStringValue(in: dict, candidates: ["routeno", "ROUTE_NO", "routeName", "route_name", "routeNm"]) ?? "알 수 없음"
        
        // routeType
        let routeTypeName = findStringValue(in: dict, candidates: ["routetp", "ROUTE_TP", "routeType", "route_type", "routeTp"]) ?? "일반"
        
        // 출발/도착지
        let startStationName = findStringValue(in: dict, candidates: ["startnodenm", "START_NODE_NM", "startNode", "start_node", "stStaNm"]) ?? "알 수 없음"
        let endStationName = findStringValue(in: dict, candidates: ["endnodenm", "END_NODE_NM", "endNode", "end_node", "edStaNm"]) ?? "알 수 없음"
        
        // 첫차/막차
        let firstBusTime = findStringValue(in: dict, candidates: ["startvehicletime", "START_VEHICLE_TIME", "firstBusTime", "first_bus_time", "firstTime"]) ?? "알 수 없음"
        let lastBusTime = findStringValue(in: dict, candidates: ["endvehicletime", "END_VEHICLE_TIME", "lastBusTime", "last_bus_time", "lastTime"]) ?? "알 수 없음"
        
        return BusRouteInfo(
            routeId: routeId,
            routeName: routeName,
            routeTypeName: routeTypeName,
            startStationName: startStationName,
            endStationName: endStationName,
            firstBusTime: firstBusTime,
            lastBusTime: lastBusTime
        )
    }
    
    // 여러 후보 키에서 문자열 값 찾기
    private func findStringValue(in dict: [String: Any], candidates: [String]) -> String? {
        for key in candidates {
            // 문자열인 경우
            if let value = dict[key] as? String {
                return value
            }
            
            // 숫자인 경우 문자열로 변환
            if let intValue = dict[key] as? Int {
                return String(intValue)
            }
            
            if let doubleValue = dict[key] as? Double {
                return String(doubleValue)
            }
            
            // 불리언인 경우 문자열로 변환
            if let boolValue = dict[key] as? Bool {
                return boolValue ? "true" : "false"
            }
        }
        
        return nil
    }
}

// MARK: - 유니버설 버스 API 파서
extension BusAPIService {
    // 유니버설 버스 정보 검색 메서드
    func universalBusRouteSearch(routeName: String, cityCode: String) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        
        // 기본 URL 및 파라미터 구성
        let baseUrl = Constants.API.baseURL
        let apiKey = Constants.apiKey
        
        // 기본 요청 URL (광역시/도)
        let urlString = "\(baseUrl)\(Constants.API.busRoute)?serviceKey=\(apiKey)&cityCode=\(cityCode)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        
        // 데이터 요청
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("유니버설 API 요청: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .mapError { NetworkError.networkFailure($0) }
            .flatMap { data -> AnyPublisher<[BusRouteInfo], NetworkError> in
                // 디버깅을 위해 원본 응답 로그
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("유니버설 API 응답: \(jsonString.prefix(500))...")
                }
                
                // 기존 파서 시도
                return self.parseWithUniversalParser(data: data)
                    .catch { error -> AnyPublisher<[BusRouteInfo], NetworkError> in
                        // 첫 번째 시도 실패 시, 다른 파라미터로 시도
                        let alternativeParams: [(name: String, value: String)] = [
                            // 5글자인 경우 2글자로 변환하여 cityCode 파라미터 사용
                            ("cityCode", cityCode.count > 2 ? String(cityCode.prefix(2)) : cityCode),
                            // 원래 코드 그대로 areaCode 파라미터 사용
                            ("areaCode", cityCode),
                            // 다른 이름의 파라미터 시도
                            ("districtCd", cityCode),
                            ("admCd", cityCode),
                            ("nodeId", cityCode)
                        ]
                        
                        // 대체 API 경로
                        let alternativePaths = [
                            Constants.API.busRoute,
                            "/BusRouteInfoInqireService/getRouteNoList",
                            "/BusRouteInfoInqireService/getCtyCodeList"
                        ]
                        
                        // 모든 조합 시도
                        return self.tryAllCombinations(
                            routeName: routeName,
                            params: alternativeParams,
                            paths: alternativePaths
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // 여러 파라미터와 경로 조합 시도
    private func tryAllCombinations(
        routeName: String,
        params: [(name: String, value: String)],
        paths: [String]
    ) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        // 첫 번째 조합 시도
        guard let firstParam = params.first else {
            return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        }
        
        let encodedRouteName = routeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routeName
        let path = paths.first ?? Constants.API.busRoute
        
        let urlString = "\(Constants.API.baseURL)\(path)?serviceKey=\(Constants.apiKey)&\(firstParam.name)=\(firstParam.value)&routeNo=\(encodedRouteName)&numOfRows=100&_type=json"
        
        print("대체 조합 시도: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: URL(string: urlString)!)
            .map(\.data)
            .mapError { NetworkError.networkFailure($0) }
            .flatMap { data -> AnyPublisher<[BusRouteInfo], NetworkError> in
                return self.parseWithUniversalParser(data: data)
                    .catch { _ -> AnyPublisher<[BusRouteInfo], NetworkError> in
                        // 남은 조합이 있으면 재귀적으로 시도
                        if params.count > 1 || paths.count > 1 {
                            var remainingParams = params
                            var remainingPaths = paths
                            
                            if params.count > 1 {
                                remainingParams.removeFirst()
                            }
                            
                            if paths.count > 1 && params.count <= 1 {
                                remainingPaths.removeFirst()
                            }
                            
                            return self.tryAllCombinations(
                                routeName: routeName,
                                params: remainingParams,
                                paths: remainingPaths
                            )
                        }
                        
                        return Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // 유니버설 파서 - 다양한 JSON 구조 처리
    private func parseWithUniversalParser(data: Data) -> AnyPublisher<[BusRouteInfo], NetworkError> {
        // 먼저 원본 데이터 확인 (JSON 형식 확인)
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return Fail(error: NetworkError.invalidData).eraseToAnyPublisher()
        }
        
        print("유니버설 파서 - JSON 키: \(jsonObject.keys)")
        
        // 1. 표준 TAGO 형식 시도 (response > body > items > item)
        if let response = jsonObject["response"] as? [String: Any],
           let body = response["body"] as? [String: Any],
           let items = body["items"] as? [String: Any],
           let itemArray = items["item"] as? [[String: Any]] {
            
            let routes = self.parseItemsToRouteInfo(items: itemArray)
            if !routes.isEmpty {
                print("표준 TAGO 형식으로 \(routes.count)개 항목 파싱 성공")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 2. 대체 형식 시도 (result > data > list)
        if let result = jsonObject["result"] as? [String: Any],
           let data = result["data"] as? [String: Any],
           let list = data["list"] as? [[String: Any]] {
            
            let routes = self.parseItemsToRouteInfo(items: list)
            if !routes.isEmpty {
                print("대체 형식(result>data>list)으로 \(routes.count)개 항목 파싱 성공")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 3. 직접 항목 배열 시도 (items > item)
        if let items = jsonObject["items"] as? [String: Any],
           let itemArray = items["item"] as? [[String: Any]] {
            
            let routes = self.parseItemsToRouteInfo(items: itemArray)
            if !routes.isEmpty {
                print("직접 항목 배열로 \(routes.count)개 항목 파싱 성공")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 4. 루트 수준 itemList 시도
        if let itemList = jsonObject["itemList"] as? [[String: Any]] {
            let routes = self.parseItemsToRouteInfo(items: itemList)
            if !routes.isEmpty {
                print("루트 itemList로 \(routes.count)개 항목 파싱 성공")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 5. msgBody > itemList 시도 (특수 API 형식)
        if let msgBody = jsonObject["msgBody"] as? [String: Any],
           let itemList = msgBody["itemList"] as? [[String: Any]] {
            
            let routes = self.parseItemsToRouteInfo(items: itemList)
            if !routes.isEmpty {
                print("msgBody > itemList로 \(routes.count)개 항목 파싱 성공")
                return Just(routes).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 6. 단일 항목 시도 (items > item이 배열이 아닌 객체인 경우)
        if let items = jsonObject["items"] as? [String: Any],
           let item = items["item"] as? [String: Any] {
            
            if let route = self.createBusRouteInfo(from: item) {
                print("단일 항목 파싱 성공")
                return Just([route]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
        }
        
        // 7. 기타 가능한 구조 탐색 (데이터 구조 로깅 후 개발자가 분석)
        print("알 수 없는 JSON 구조: \(jsonObject.keys)")
        return Fail(error: NetworkError.invalidData).eraseToAnyPublisher()
    }

    // 다양한 필드 이름을 가진 항목 배열에서 BusRouteInfo 배열 생성
    private func parseItemsToRouteInfo(items: [[String: Any]]) -> [BusRouteInfo] {
        var result: [BusRouteInfo] = []
        
        for item in items {
            if let route = self.createBusRouteInfo(from: item) {
                result.append(route)
            }
        }
        
        return result
    }
}
