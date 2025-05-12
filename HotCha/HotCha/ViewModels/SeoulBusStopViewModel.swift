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
import CoreLocation
import SwiftData

class BusStopSeoulViewModel: ObservableObject {
    @Published var bus: Bus_info_seoul?
    
    @Published var busStations: [BusStop] = []
    @Published var defaultBusStations: [BusStop] = [] // 미정차 구역이 필터링 된 정류장 노선도
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false // 현재 버스가 로딩되고 있는지 확인하는 변수
    @Published var errorMessage: String?
    //    @Published var stationsUpdated: Bool = false // 데이터 업데이트 알림용 플래그
    @Published var currentFilteredIndex: Int = 0 // 필터링 인덱스 스크롤을 위한
    @Published var isLastFilteredIndex: Bool = true // 마지막 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    @Published var isFirstFilteredIndex: Bool = true // 첫번째 필터링 인덱스 버튼 색상을 위한, 인덱스 없는 경우도 true
    // 현재 선택된 목적지의 인덱스를 저장할 변수 추가, 이전에 선택된 것을 초기화 하기위해 필요
    @Published var currentDestinationIndex: Int? = nil
    @Published var currentAlarmIndex: Int? = nil // 이전에 선택된 알람의 상태를 초기화 하기 위해 필요
    @Published var currentBusStopIndex: Int? = nil // 현재 정류장 인덱스 몇 정류장 차이인지 구하기 위해
    @Published var searchTextFieldfocused: Bool = false // textField가 정류장 선택을 누르면 초기화 되도록 하기위함
    
    // 현재 모드 (true면 목적지 or false면 알람 선택)
    @Published var isSelectDestinationMode: Bool = true
    // 알람 종료뷰로 이동하기위한 트리거
    @Published var navigateToAlarmEndView = false
    // 알람을 시작하고 뷰를 떠났다가 다시 현재 상태 그대로 돌아와야할때 사용하는 트리거 ex) 알람종료뷰에서 돌아올때, 메인 뷰에서 돌아올 때
    @Published var isReload = false
    @Published var returnToRootView = false // 안내 종료 시 sheet가 닫히고 View도 dismiss되도록 하기위한 용도
    
    
    
    func setupBus(bus: Bus_info_seoul) {
        self.bus = bus
    }
    
    // Route ID를 직접 인자로 받아 데이터를 가져오는 메서드
    func fetchBusStations(routeid: String, completion: @escaping (Bool) -> Void) {
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
                    self?.filteringDisabledStation() // 미정차 구역 필터링
                    // 검색어가 있는 경우 필터링 다시 적용
                    if !(self?.searchText.isEmpty ?? true) {
                        self?.applyFiltering(with: self?.searchText ?? "")
                    }
                }
            }
        }
        
        completion(true)
    }
    
    // 미정차 구역 필터링
    func filteringDisabledStation(){
        guard !busStations.isEmpty else { return }
        applyFilteringDisableStation(with: "미정차")
        applyFilteringDisableStation(with: "가상")
        
        defaultBusStations = busStations
    }
    
    // 미정차 정류장 필터링
    // disabled가 true면 미운행 정류장 필터링, false면 Search textField 필터링
    func applyFilteringDisableStation(with searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 모든 정류장의 상태 업데이트
        var updatedStations = busStations
        for i in 0..<updatedStations.count {
            // locale을 고려한 문자열 검색, 대소문자 무시
            let stationName = updatedStations[i].stationNm
            if stationName.range(of: trimmedText, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                // 미운행 정류장 필터링
                updatedStations[i].busStopCase = .disableStop
            }
        }
        
        // 상태 업데이트
        busStations = updatedStations
    }
    // TODO: 목적지 이후 정류징 disable
    
    
    // 다른 정류장을 목적지로 선택 시 이전 목적지 상태를 ableStop으로 초기화함
    func clearDestinationStation(destIndex: Int) {
        let filtered = filteredStations
        //필터링 리스트에 없으면 일반 정류장으로, 있으면 필터링 정류장으로 초기화
        if filtered.contains(where: { $0.stationNm == busStations[destIndex].stationNm }) {
            busStations[destIndex].busStopCase = .filteredStop
        } else {
            if busStations[destIndex].busStopCase.contains(.currentStop) {
                busStations[destIndex].busStopCase = .currentStop
            }
            else { busStations[destIndex].busStopCase = .ableStop }
        }
        busStations[destIndex].arrivalStation = false
        
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
            
            return nil
        }
        return filtered[currentFilteredIndex].id
    }
    
    // 필터링
    func applyFiltering(with searchText: String) { // disabled가 true면 미운행 정류장 필터링, false면 Search textField 필터링
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
                if busStations[i].busStopCase != .destinationStop || busStations[i].busStopCase != .disableStop { // 검색어 필터링
                    updatedStations[i].busStopCase = .filteredStop
                }
                updatedStations[i].filtered = true
            } else {
                // 검색어에 맞지 않으면 필터링 해제
                updatedStations[i].filtered = false
                if busStations[i].busStopCase != .destinationStop || busStations[i].busStopCase != .disableStop {
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
    
    
    //
    //    // 현재 모드 (true면 목적지 or false면 알람 선택)
    //    @Published var isSelectDestinationMode: Bool = true
    
    // 목적지 정류장 이후 disable
    func disableAfterDestinationStation(){
        // 목적지 정류장 인덱스 확인
        guard let destIndex = getDestinationStationIndex() else { return }
        
        // 모든 정류장 알람 상태 초기화
        for i in (destIndex + 1)..<busStations.count {
            busStations[i].busStopCase = .disableStop
        }
    }
    
    // 도착 정류장 선택 메서드
    func selectDestinationStation(destIndex: Int) {
        guard destIndex >= 0 && destIndex < busStations.count else { return }
        // 미운행 정류장이 아니면
        guard busStations[destIndex].busStopCase != .disableStop else { return }
        
        // 이전에 선택된 목적지가 있다면 초기화
        if let currentDestIndex = currentDestinationIndex {
            clearDestinationStation(destIndex: currentDestIndex)
        }
        
        // 새 목적지 설정
        if busStations[destIndex].busStopCase == .currentStop { // 현재 위치한 정류장으로 알람 정류장을 옮기면 둘다 포함되도록
            busStations[destIndex].busStopCase = .bothCurrentBusWithDest
        } else {
            busStations[destIndex].busStopCase = .destinationStop
        }
        busStations[destIndex].arrivalStation = true
        print("selected destination: \(busStations[destIndex].stationNm)")
        
        // 현재 목적지 인덱스 업데이트
        currentDestinationIndex = destIndex
    }
    
    // 알람 정류장 선택 메서드
    func selectAlarmStation(alarmIndex: Int) {
        @AppStorage("alarmStopDistanceFromDestination") var alarmStopDistanceFromDestination: Int = 2
        
        // disable 정류장이 아니면
        guard busStations[alarmIndex].busStopCase != .disableStop else { return }
        
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
        if busStations[finalIndex].busStopCase.contains(.currentStop) {
            busStations[finalIndex].busStopCase = .bothCurrentBusWithAlarm
        } else {
            busStations[finalIndex].busStopCase = .alarmStop
        }
        // 현재 알람정류장 인덱스 업데이트
        currentAlarmIndex = finalIndex
        
        // 알람 정류장과 도착 정류장 사이의 distance 계산
        alarmStopDistanceFromDestination = destIndex - finalIndex
        print("alarmStopDistanceFromDestination: \(alarmStopDistanceFromDestination)")
    }
    
    // 목적지 정류장 인덱스 찾기
    func getDestinationStationIndex() -> Int? {
        return busStations.firstIndex(where: { $0.arrivalStation })
    }
    
    // 알람 정류장 인덱스 찾기
    func getAlarmStationIndex() -> Int? {
        return busStations.firstIndex(where: { $0.alarmStation })
    }
    
    // TODO: 알람 정류장 설정 버튼 (다른 View에서 호출) 미정차 정류장 고려해서 수정
    func setAlarmNStationsBeforeDestination() {
        @AppStorage("alarmStopDistanceFromDestination") var alarmStopDistanceFromDestination: Int = 2 // 알람 정류장과 도착 정류장 사이의 distance
        // 목적지 정류장 확인
        guard let destIndex = getDestinationStationIndex() else { return }
        
        // 목적지에서 2정류장 전의 위치 계산 (최소 0)
        let alarmIndex = max(0, destIndex - alarmStopDistanceFromDestination)
        
        // 알람 정류장 설정
        selectAlarmStation(alarmIndex: alarmIndex)
        
        // 드래그 모드를 알람 모드로 변경
        isSelectDestinationMode = false
    }
    
    // 목적지 설정 모드로 전환 (다른 View에서 호출)
    func switchToDestinationMode() {
        isSelectDestinationMode = true
        
        busStations = defaultBusStations // 초기 리스트로 초기화
        // 선택된 목적지 유지
        busStations[currentDestinationIndex ?? 0].busStopCase = .destinationStop
        busStations[currentDestinationIndex ?? 0].arrivalStation = true
        // 알람정류장 초기화
        busStations[currentAlarmIndex ?? 0].busStopCase = .ableStop
        busStations[currentAlarmIndex ?? 0].alarmStation = false
        currentAlarmIndex = nil
        
        // 현재 정류장 초기화
        if let currBusStopIndex = currentBusStopIndex {
            busStations[currBusStopIndex].busStopCase = .ableStop
            currentBusStopIndex = nil
        }
        isReload = false
    }
    
    func switchToAlarmMode() {
        isSelectDestinationMode = false
    }
    
    func currentBusLocationMapping(nextStId: String) {
        @AppStorage("soundToggle") var soundToggle: Bool = true
        @AppStorage("vibrationToggle") var vibrationToggle: Bool = true
        
        print("현재 버스 위치 매핑 - 정류장 ID: \(nextStId)")
        
        // 먼저 이전에 .currentStop으로 표시된 정류장의 상태를 복원
        for i in 0..<busStations.count {
            if busStations[i].busStopCase.contains(.currentStop) {
                // 이전 상태로 복원 (필터링, 목적지, 알람 정류장 상태를 고려)
                if busStations[i].arrivalStation || busStations[i].busStopCase.contains(.destinationStop){
                    busStations[i].busStopCase = .destinationStop
                } else if busStations[i].alarmStation || busStations[i].busStopCase.contains(.alarmStop) {
                    busStations[i].busStopCase = .alarmStop
                } else if busStations[i].busStopCase != .disableStop {
                    busStations[i].busStopCase = .ableStop
                }
            }
        }
        // 현재 버스 위치 정류장 찾기
        if let index = busStations.firstIndex(where: { $0.station == nextStId }) {
            if busStations[index].busStopCase.contains(.alarmStop) {
                // 알람 정류장과 현재 정류장 위치가 같으면 OptionSet으로 두 상태를 함께 나타냄
                busStations[index].busStopCase = .bothCurrentBusWithAlarm
            } else if (busStations[index].busStopCase.contains(.destinationStop)) {
                // 알람 정류장과 현재 정류장 위치가 같으면 OptionSet으로 두 상태를 함께 나타냄
                busStations[index].busStopCase = .bothCurrentBusWithDest
            } else {
                // 정류장 상태를 현재 버스 위치로 변경
                busStations[index].busStopCase = .currentStop
            }
            
            currentBusStopIndex = index // 현재 정류장 인덱스 매핑
            
            print("현재 버스 위치 정류장: \(busStations[index].stationNm)")
            
//            let distance = distanceToDestinationStop()
            
            // 알람 모드에서 현재 정류장이 알람 정류장인지 체크
            if !isSelectDestinationMode, let alarmIndex = getAlarmStationIndex() {
                if index == alarmIndex {
                    // 알람 정류장에 도착 - 여기서 알람 로직을 추가할 수 있음
                    print("🔔 알람 정류장에 도착!")
//                    // 알람 울리기
//                    startAlarmToggle(
//                        isOn: true,
//                        title: "핫챠! 내릴 준비를 해주세요",
//                        body: "도착까지 \(String(describing: distanceToDestinationStop()))정거장 남았어요!",
//                        useSound: soundToggle,
//                        useVibration: vibrationToggle
//                    )
                    
                    // 알람종료뷰로 이동하기 위한 트리거, 알람 이동중에 현재 버스 위치가 겹친 걸로 알람이 울리지 않게 하기위한 장치
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if let alarmIndex = self.getAlarmStationIndex(), index == alarmIndex {
                            self.navigateToAlarmEndView = true
                        }
                    }
                    print("navigateToAlarmEndView \(navigateToAlarmEndView)")
                }
            }
        } else {
            print("경고: 정류장 ID \(nextStId)를 찾을 수 없습니다.")
        }
    }
    
    func closeAllSheets(using sheetManager: AlarmSettingModalSheetManager) {
        // 종료뷰를 위해 시트 모두 닫음
        sheetManager.showAlarmSearchSheet1 = false
        sheetManager.showAlarmInfoSheet2 = false
    }
    
//    // 목적지와 현재 정류장 수의 차이를 계산
//    func distanceToDestinationStop() -> Int?{
//        var distanceStopNum: Int = 0
//        // 도착 정류장에서 남은 버스 정류장 distance를 담은 변수
//        @AppStorage("remainingStops") var remainingStops: String = "불러오는 중"
//        
//        if let destIndex = getDestinationStationIndex(), let currIndex = currentBusStopIndex {
//            distanceStopNum = destIndex - currIndex
//            if distanceStopNum >= 0 {
//                remainingStops = "\(abs(distanceStopNum))정거장 전"
//            } else {
//                remainingStops = "\(abs(distanceStopNum))정거장 후"
//            }
//        }
//        return distanceStopNum
//    }
//    
    // 알람을 시작하지 않고 떠날 때 선택된 데이터 clear
    func clearSelectedData(){
        bus = nil
        busStations = []
        defaultBusStations = []
        searchText = ""
        currentDestinationIndex = nil
    }
    
    // 알람을 아에 종료 할 때 이용기록 저장 및 데이터 초기화
    func leaveAlarm(){
        @Environment(\.modelContext) var modelContext
        // 현재 진행중인 알람이 있는지 여부
        @AppStorage("isAlarmInProgress") var isAlarmInProgress: Bool = false
        // 도착 정류장에서 남은 버스 정류장 distance를 담은 변수
        @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."
        
        
        // 데이터 초기화
        self.bus = nil
        self.busStations = []
        self.defaultBusStations = []
        self.searchText = ""
        //            self.isLoading = false
        //        currentFilteredIndex = 0
        //        isLastFilteredIndex = false
        self.currentDestinationIndex = nil
        self.currentAlarmIndex = nil
        self.currentBusStopIndex = nil
        self.searchTextFieldfocused = false
        self.isSelectDestinationMode = true
        self.navigateToAlarmEndView = false
        self.isReload = false
        self.returnToRootView = false
        
        isAlarmInProgress = false
        remainingStops = "불러오는 중..."
        
    }
    
    // 알람을 잠시 떠날 때 상태 저장
}

