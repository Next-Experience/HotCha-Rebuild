//
//  SeoulBusStopViewModel.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//

// 서울 버스스탑을 가지고 옴

import SwiftUI
import Foundation

class BusStopSeoulViewModel: ObservableObject {
    @Published var busStations: [BusStop] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var stationsUpdated: Bool = false // 데이터 업데이트 알림용 플래그
    
    // Route ID를 직접 인자로 받아 데이터를 가져오는 메서드
    func fetchBusStations(routeid: String) {
        guard !routeid.isEmpty else {
            errorMessage = "Route ID를 입력하세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        HotCha.fetchBusStations(routeId: routeid) { [weak self] stations, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error
                } else {
                    self?.busStations = stations
                    self?.setFirstAndLastFlags()
                    
                    // 검색어가 있는 경우 필터링 다시 적용
                    if !(self?.searchText.isEmpty ?? true) {
                        self?.applyFiltering(with: self?.searchText ?? "")
                    }
                    
                    // 데이터 업데이트 알림
                    self?.notifyStationsUpdated()
                }
            }
        }
    }
    
    //        // 검색어 업데이트 및 필터링 적용
    //        func updateSearchText(_ newText: String) {
    //            searchText = newText
    //            applyFiltering(with: newText)
    //            // 데이터 업데이트 알림
    //            notifyStationsUpdated()
    //        }
    
    func applyFiltering(with searchText: String) {
        self.searchText = searchText
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 필터링 초기화 (검색어가 비어있으면)
        if trimmedText.isEmpty {
            clearFiltering()
            return
        }
        
        // 디버깅용 로그
        print("원본 정류장 목록:")
        for station in busStations {
            print("정류장: \(station.stationNm)")
        }
        
        // 모든 정류장의 상태 업데이트
        var updatedStations = busStations
        var matchCount = 0
        
        for i in 0..<updatedStations.count {
            // 디버깅: 각 정류장과 검색어를 출력
            print("비교: '\(updatedStations[i].stationNm)' vs '\(trimmedText)'")
            print("포함여부: \(updatedStations[i].stationNm.contains(trimmedText))")
            
            // 정류장 이름이 검색어를 포함하면 filteredStop으로 변경
            if updatedStations[i].stationNm.contains(trimmedText) {
                // 중요 상태가 아닌 정류장만 필터링 상태로 변경
//                if ![.alarmStop, .currentStop, .destinationStop].contains(updatedStations[i].busStopCase) {
                    updatedStations[i].busStopCase = .filteredStop
                    matchCount += 1
//                }
            }
        }
        
        // 상태 업데이트
        busStations = updatedStations
        
        // 데이터 변경 알림
        notifyStationsUpdated()
        
        print("🔍 검색어: \(trimmedText)")
        print("🔍 필터링된 정류장 수: \(matchCount)")
    }
    
    // 필터링 적용
//    func applyFiltering(with searchText: String) {
//        self.searchText = searchText
//        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//        
//        // 필터링 초기화 (검색어가 비어있으면)
//        if trimmedText.isEmpty {
//            clearFiltering()
//            return
//        }
//        
//        
//        /// 모든 정류장의 상태 업데이트
//        var updatedStations = busStations
//        for i in 0..<updatedStations.count {
//            // 정류장 이름이 검색어를 포함하면 filteredStop으로 변경, 그렇지 않으면 기존 상태 유지
//            // 단, alarmStop, currentStop, destinationStop은 우선순위가 높으므로 그대로 유지
//            if updatedStations[i].stationNm.lowercased().contains(trimmedText) {
//                // 중요 상태(알람, 현재, 도착)가 아닌 정류장만 필터링 상태로 변경
//                if ![.alarmStop, .currentStop, .destinationStop].contains(updatedStations[i].busStopCase) {
//                    updatedStations[i].busStopCase = .filteredStop
//                }
//            }
//        }
//        
//        // 상태 업데이트
//        busStations = updatedStations
//        
//        // 데이터 변경 알림
//        notifyStationsUpdated()
//        
//        print("🔍 검색어: \(trimmedText)")
//        print("🔍 필터링된 정류장 수: \(updatedStations.filter { $0.busStopCase == .filteredStop }.count)")
//    }
    
    // 필터링 초기화
    func clearFiltering() {
        searchText = ""
        var updatedStations = busStations
        
        for i in 0..<updatedStations.count {
            // filteredStop 상태의 정류장만 원래의 ableStop으로 복원
            if updatedStations[i].busStopCase == .filteredStop {
                updatedStations[i].busStopCase = .ableStop
            }
        }
        
        busStations = updatedStations
        
        // 데이터 변경 알림
        notifyStationsUpdated()
    }
    
    // 데이터 업데이트 알림
    private func notifyStationsUpdated() {
        // Bool 토글로 변경 감지
        stationsUpdated.toggle()
    }
    
    func setFirstAndLastFlags() {
        guard !busStations.isEmpty else { return }
        print("Flag Setting")
        
        if let minSeq = busStations.map(\.seq).min(),
           let maxSeq = busStations.map(\.seq).max() {
            
            var updatedStations = busStations
            for i in 0..<updatedStations.count {
                if updatedStations[i].seq == minSeq {
                    updatedStations[i].isFirstStop = true
                }
                
                if updatedStations[i].seq == maxSeq {
                    updatedStations[i].isLastStop = true
                }
            }
            
            busStations = updatedStations
        }
        
        print("Flag Setting Last")
    }
}

