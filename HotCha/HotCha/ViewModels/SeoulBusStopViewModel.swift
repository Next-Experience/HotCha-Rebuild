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
    @Published var currentFilteredIndex: Int = 0 // 필터링 인덱스 스크롤을 위한
    @Published var isLastFilteredIndex: Bool = true // 마지막 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    @Published var isFirstFilteredIndex: Bool = true // 첫번째 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    // 현재 선택된 목적지의 인덱스를 저장할 변수 추가
    private var currentDestinationIndex: Int? = nil
    
    
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
    
    // 목적지로 선택된 정류장을 목적지로 변경
    func selectDestinationStataion(destIndex: Int) {
        // 이전에 선택된 목적지가 있다면 초기화
        if let currentDestIndex = currentDestinationIndex {
            clearDestinationStation(destIndex: currentDestIndex)
        }
        
        // 새 목적지 설정
        busStations[destIndex].busStopCase = .destinationStop
        print("selected destination: \(busStations[destIndex].stationNm)")
        
        // 현재 목적지 인덱스 업데이트
        currentDestinationIndex = destIndex
        
        // 데이터 업데이트 알림
        notifyStationsUpdated()
    }
    
    // 다른 정류장을 목적지로 선택 시 이전 목적지 상태를 ableStop으로 초기화함
    func clearDestinationStation(destIndex: Int) {
        busStations[destIndex].busStopCase = .ableStop
    }
    
    
    // 필터링된 정류장 목록 받아오기
    var filteredStations: [BusStop] {
        return busStations.filter { $0.busStopCase == .filteredStop }
    }
    
    
    
    // 이전 필터링 항목으로 이동
    func moveToPreviousFilteredStation() {
        let filtered = filteredStations
        if !filtered.isEmpty {
            if currentFilteredIndex != 0 { // 첫번째 인덱스가 아니면
                currentFilteredIndex = (currentFilteredIndex - 1 + filtered.count) % filtered.count
                isFirstFilteredIndex = currentFilteredIndex == 0 ? true : false
                isLastFilteredIndex = false
                }
            } else {
                isFirstFilteredIndex = true
            }
        }
    
    // 다음 필터링 항목으로 이동
    func moveToNextFilteredStation() {
        let filtered = filteredStations
        if !filtered.isEmpty {
            if currentFilteredIndex != filtered.count - 1 { // 마지막 인덱스가 아니면
                currentFilteredIndex = (currentFilteredIndex + 1) % filtered.count
                isLastFilteredIndex = currentFilteredIndex == filtered.count - 1 ? true : false
                isFirstFilteredIndex = false
            } else {
                isLastFilteredIndex = true
            }
        }
    }
    
    // 현재 선택된 필터링 항목의 ID
    var currentFilteredStationID: UUID? {
        let filtered = filteredStations
        return filtered.isEmpty ? nil : filtered[currentFilteredIndex].id
    }
    
    // 필터링
    func applyFiltering(with searchText: String) {
        self.searchText = searchText
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 필터링 초기화 (검색어가 비어있으면)
        if trimmedText.isEmpty {
            clearFiltering()
            return
        }
        
        // 모든 정류장의 상태 업데이트
        var updatedStations = busStations
        for i in 0..<updatedStations.count {
            // 정류장 이름이 검색어를 포함하면 filteredStop으로 변경
            if updatedStations[i].stationNm.contains(trimmedText) {
                // 중요 상태가 아닌 정류장만 필터링 상태로 변경
                if ![.alarmStop, .currentStop, .destinationStop].contains(updatedStations[i].busStopCase) {
                    updatedStations[i].busStopCase = .filteredStop
                }
            }
        }
        
        // 상태 업데이트
        busStations = updatedStations
        
        // 필터링 결과가 있으면 인덱스 초기화
        if !filteredStations.isEmpty {
            currentFilteredIndex = 0
            isLastFilteredIndex = false
        }
        
        // 데이터 변경 알림
        notifyStationsUpdated()
    }
    
    // 필터링 초기화 시 인덱스도 초기화
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
        currentFilteredIndex = 0
        isFirstFilteredIndex = true
        isLastFilteredIndex = true
        
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
