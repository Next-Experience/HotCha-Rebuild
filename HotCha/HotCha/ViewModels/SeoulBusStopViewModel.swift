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
    @Published var filteredBusStations: [BusStop] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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
                }
            }
        }
    }
    
    func filteredBusStations(searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmedText.isEmpty {
            filteredBusStations = busStations // 검색어 없으면 전체
        } else {
            filteredBusStations = busStations.filter {
                $0.stationNm.lowercased().contains(trimmedText)
            }
        }
        print("🔍 원본 정류장 수: \(busStations.count)")
        print("Filtered Bus Stations: \(filteredBusStations.count)개, \(filteredBusStations)")
    }
    
//    func filteredBusStations(searchText: String) {
////        filteredBusStations.removeAll()
//        filteredBusStations = busStations.filter {
//            $0.nodenm.lowercased().contains(searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
//        }
//        
//        print("Filtered Bus Stations: \(filteredBusStations)")
//    }
//    
    func setFirstAndLastFlags() {
        guard !busStations.isEmpty else { return }
        print("Flag Setting")
        
        if let minSeq = busStations.map(\.seq).min(),
           let maxSeq = busStations.map(\.seq).max() {
            
            busStations = busStations.map { stop in
                var busStop = stop
                if busStop.seq == minSeq {
                    busStop.isFirstStop = true
                }
                    
                if busStop.seq == maxSeq {
                    busStop.isLastStop = true
                }
                
                print("nodeord: \(busStop.seq) \(busStop.isFirstStop) \(busStop.isLastStop)")
                
                return busStop
            }
        }
        
        print("Flag Setting Last")
    }
}
