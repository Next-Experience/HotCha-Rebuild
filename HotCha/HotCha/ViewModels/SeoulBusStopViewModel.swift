//
//  SeoulBusStopViewModel.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//

// 서울 버스스탑을 가지고 옴

import SwiftUI
import Foundation
import Combine

class BusStopSeoulViewModel: ObservableObject {
    @Published var busStations: [BusStop] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var stationsUpdated: Bool = false // 데이터 업데이트 알림용 플래그
    @Published var currentFilteredIndex: Int = 0 // 필터링 인덱스 스크롤을 위한
    @Published var isLastFilteredIndex: Bool = true // 마지막 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    @Published var isFirstFilteredIndex: Bool = true // 첫번째 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    // 현재 선택된 목적지의 인덱스를 저장할 변수 추가, 이전에 선택된 것을 초기화 하기위해 필요
    @Published var currentDestinationIndex: Int? = nil
    @Published var currentAlarmIndex: Int? = nil
    @Published var searchTextFieldfocused: Bool = false // textField가 정류장 선택을 누르면 초기화 되도록 하기위함
    
    
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
    
//    // 목적지로 선택된 정류장을 목적지로 변경
//    func selectDestinationStataion(destIndex: Int) {
//        // 이전에 선택된 목적지가 있다면 초기화
//        if let currentDestIndex = currentDestinationIndex {
//            clearDestinationStation(destIndex: currentDestIndex)
//        }
//        
//        // 새 목적지 설정
//        busStations[destIndex].busStopCase = .destinationStop
//        busStations[destIndex].arrivalStation = true
//        print("selected destination: \(busStations[destIndex].stationNm)")
//        
//        // 현재 목적지 인덱스 업데이트
//        currentDestinationIndex = destIndex
//        
//        // 데이터 업데이트 알림
//        notifyStationsUpdated()
//    }
    
    // 다른 정류장을 목적지로 선택 시 이전 목적지 상태를 ableStop으로 초기화함
    func clearDestinationStation(destIndex: Int) {
        let filtered = filteredStations
        //필터링 리스트에 없으면 일반 정류장으로, 있으면 필터링 정류장으로 초기화
        if filtered.contains(where: { $0.stationNm == busStations[destIndex].stationNm }) {
            busStations[destIndex].busStopCase = .filteredStop
        } else {
            busStations[destIndex].busStopCase = .ableStop
        }
        busStations[destIndex].arrivalStation = false
    }
    
    // 선택된 목적지 정류장을 저장
    func storeDestinationStation() {
        if let currentDestIndex = currentDestinationIndex {
            searchText = busStations[currentDestIndex].stationNm
        }
    }
    
    
    // 이전 필터링 항목으로 이동 (버튼)
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
    
    // 다음 필터링 항목으로 이동 (버튼)
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
    
    // 필터링된 정류장 목록 받아오기
    var filteredStations: [BusStop] {
        return busStations.filter { $0.filtered == true }
    }
    
    // 현재 선택된 필터링 항목의 ID
    var currentFilteredStationID: UUID? {
        let filtered = filteredStations
        // 배열이 비어있거나 인덱스가 범위를 벗어나면 nil 반환
        guard !filtered.isEmpty, currentFilteredIndex >= 0, currentFilteredIndex < filtered.count else {
            print("필터링된 배열의 범위가 잘못되었습니다.")
            return nil
        }
        return filtered[currentFilteredIndex].id
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
            // locale을 고려한 문자열 검색, 대소문자 무시
            let stationName = updatedStations[i].stationNm
            if stationName.range(of: trimmedText, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                if busStations[i].busStopCase != .destinationStop {
                    updatedStations[i].busStopCase = .filteredStop
                }
                updatedStations[i].filtered = true
            } else {
                // 검색어에 맞지 않으면 필터링 해제
                updatedStations[i].filtered = false
                if busStations[i].busStopCase != .destinationStop {
                    updatedStations[i].busStopCase = .ableStop
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
            // filtered가 true인 상태의 정류장만 필터링 해제
            if updatedStations[i].filtered == true {
                updatedStations[i].filtered = false
                // destinationStop이 아닌 정류장만 기본 정류장으로 초기화 (UI)
                if updatedStations[i].busStopCase != .destinationStop {
                    updatedStations[i].busStopCase = .ableStop
                }
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
    
    // 처음 정류장과 마지막 정류장을 구분
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
    

        // 현재 드래그 모드 (목적지 or 알람)
        @Published var isDraggingDestination: Bool = true
        // 도착 정류장 선택 메서드
        func selectDestinationStation(destIndex: Int) {
            guard destIndex >= 0 && destIndex < busStations.count else { return }
            
            // 이전에 선택된 목적지가 있다면 초기화
            if let currentDestIndex = currentDestinationIndex {
                clearDestinationStation(destIndex: currentDestIndex)
            }
            
            // 새 목적지 설정
            busStations[destIndex].busStopCase = .destinationStop
            busStations[destIndex].arrivalStation = true
            print("selected destination: \(busStations[destIndex].stationNm)")
            
            // 현재 목적지 인덱스 업데이트
            currentDestinationIndex = destIndex
            
            // 데이터 업데이트 알림
            notifyStationsUpdated()
            /////
            // 모든 정류장의 도착 상태 초기화
//            for i in 0..<busStations.count {
//                busStations[i].arrivalStation = false
//            }
            
//            // 알람 정류장이 목적지 정류장 이후에 있다면 조정
//            if let alarmIndex = getAlarmStationIndex(), alarmIndex >= destIndex {
//                // 알람 정류장을 목적지 이전으로 이동 (최소 2정류장 전, 없으면 가장 가까운 정류장)
//                selectAlarmStation(alarmIndex: max(0, destIndex - 2))
//            }
            
            // 필터링된 정류장 업데이트 (스크롤 위치를 위해)
//            // 모든 정류장 필터링 상태 초기화
//            for i in 0..<busStations.count {
//                busStations[i].filtered = false
//            }
            
//            // 선택된 정류장을 필터링 상태로 설정
//            busStations[destIndex].filtered = true
//            
//            currentDestinationIndex = destIndex
            
          
            // 데이터 업데이트 알림
            notifyStationsUpdated()
        }
        
        // 알람 정류장 선택 메서드
        func selectAlarmStation(alarmIndex: Int) {
            // 목적지 정류장 인덱스 확인
            guard let destIndex = getDestinationStationIndex() else { return }
            
            // 이전에 선택된 알람 정류장이 있다면 초기화
            if let currentAlarmIndex = currentAlarmIndex {
                clearDestinationStation(destIndex: currentAlarmIndex)
            }
            
            // 알람 정류장은 목적지 정류장 이전에만 위치 가능
            let validIndex = min(destIndex - 1, alarmIndex)
            
            // 인덱스 범위 확인 (0보다 작을 수 없음)
            let finalIndex = max(0, validIndex)
            
            guard finalIndex >= 0 && finalIndex < busStations.count else { return }
            
            // 모든 정류장 알람 상태 초기화
            for i in 0..<busStations.count {
                busStations[i].alarmStation = false
            }
            
            // 선택된 정류장 알람 설정
            busStations[finalIndex].alarmStation = true
            busStations[finalIndex].busStopCase = .alarmStop
            // 현재 알람정류장 인덱스 업데이트
            currentAlarmIndex = finalIndex
        }
        
        // 목적지 정류장 인덱스 찾기
        func getDestinationStationIndex() -> Int? {
            return busStations.firstIndex(where: { $0.arrivalStation })
        }
        
        // 알람 정류장 인덱스 찾기
        func getAlarmStationIndex() -> Int? {
            return busStations.firstIndex(where: { $0.alarmStation })
        }
    
        // 알람 설정 버튼 (다른 View에서 호출)
        func setAlarmTwoStationsBeforeDestination() {
            // 목적지 정류장 확인
            guard let destIndex = getDestinationStationIndex() else { return }
            
            // 목적지에서 2정류장 전의 위치 계산 (최소 0)
            let alarmIndex = max(0, destIndex - 2)
            
            // 알람 정류장 설정
            selectAlarmStation(alarmIndex: alarmIndex)
            
            // 드래그 모드를 알람 모드로 변경
            isDraggingDestination = false
        }
        
        // 목적지 설정 모드로 전환 (다른 View에서 호출)
        func switchToDestinationMode() {
            isDraggingDestination = true
            if let alarmIndex = getAlarmStationIndex() {
                busStations[alarmIndex].alarmStation = false
                busStations[alarmIndex].busStopCase = .ableStop
                
            }
        }
        
        // 알람 설정 모드로 전환 (다른 View에서 호출)
        func switchToAlarmMode() {
            isDraggingDestination = false
        }
    }
