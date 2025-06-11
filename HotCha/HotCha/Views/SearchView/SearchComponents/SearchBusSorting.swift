//
//  SearchBusSorting.swift
//  HotCha
//
//  Created by 문호 on 5/12/25.
//

import Foundation

struct SearchBusSorting {
    
    // 정규식 캐싱
    private static let digitRegex = try? NSRegularExpression(pattern: "\\d+")
    
    // 버스 노선에서 숫자만 추출하는 함수
    static func extractNumber(from routeNumber: String) -> Int {
        guard let regex = digitRegex,
              let match = regex.firstMatch(in: routeNumber, range: NSRange(routeNumber.startIndex..., in: routeNumber)),
              let range = Range(match.range, in: routeNumber) else {
            return 0
        }
        
        let numberStr = String(routeNumber[range])
        return Int(numberStr) ?? 0
    }
    
    // 검색어와 일치하는 순으로 정렬하는 함수
    static func sortBusesBySearchRelevance(buses: [Bus_info_seoul], searchText: String) -> [Bus_info_seoul] {
        // 검색어가 비어있으면 기본 순서 반환
        guard !searchText.isEmpty else { return buses }
        
        // 검색어가 숫자인지 확인
        let isNumericSearch = searchText.allSatisfy { $0.isNumber }
        
        return buses.sorted { bus1, bus2 in
            // 1. 검색어로 시작하는 버스 노선을 우선 정렬
            let bus1StartsWithQuery = bus1.busRouteNm.hasPrefix(searchText)
            let bus2StartsWithQuery = bus2.busRouteNm.hasPrefix(searchText)
            
            if bus1StartsWithQuery && !bus2StartsWithQuery {
                return true
            } else if !bus1StartsWithQuery && bus2StartsWithQuery {
                return false
            }
            
            // 2. 숫자 검색인 경우 숫자 값으로 정렬
            if isNumericSearch {
                let num1 = extractNumber(from: bus1.busRouteNm)
                let num2 = extractNumber(from: bus2.busRouteNm)
                return num1 < num2
            }
            
            // 3. 그 외의 경우 자연 정렬 순서 사용
            return bus1.busRouteNm.localizedStandardCompare(bus2.busRouteNm) == .orderedAscending
        }
    }
    
    // 검색 기준에 맞는 버스 노선 필터링 함수
    static func filterBuses(buses: [Bus_info_seoul], searchText: String) -> [Bus_info_seoul] {
        guard !searchText.isEmpty else { return buses }
        
        // 검색어가 숫자인지 확인
        let isNumericSearch = searchText.allSatisfy { $0.isNumber }
        let lowercasedSearch = searchText.lowercased()
        
        let filteredBuses = buses.filter { bus in
            // 대소문자 구분 없이 검색
            let lowercasedRouteNm = bus.busRouteNm.lowercased()
            let lowercasedRouteAbrv = bus.busRouteAbrv.lowercased()
            
            // 버스 번호나 약어에 검색어가 포함되는지 확인
            let matchesRouteNm = lowercasedRouteNm.contains(lowercasedSearch)
            let matchesRouteAbrv = lowercasedRouteAbrv.contains(lowercasedSearch)
            
            // 숫자 검색인 경우 추가 로직
            if isNumericSearch {
                // 노선 번호에서 숫자 추출 (예: "M5633"에서 "5633" 추출)
                let routeNumber = extractNumber(from: bus.busRouteNm)
                // 추출된 숫자가 검색어로 시작하는지 확인
                let numberStartsWithQuery = String(routeNumber).hasPrefix(searchText)
                
                return matchesRouteNm || matchesRouteAbrv || numberStartsWithQuery
            }
            
            return matchesRouteNm || matchesRouteAbrv
        }
        
        // 정렬된 결과 반환
        return sortBusesBySearchRelevance(buses: filteredBuses, searchText: searchText)
    }
}
