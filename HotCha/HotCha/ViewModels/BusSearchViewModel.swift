//
//  BusSearchViewModel.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation
import Combine

// BusSearchViewModel.swift - 통합 검색 ViewModel
class BusSearchViewModel: ObservableObject {
    @Published var cityCode: String = ""
    @Published var busNumber: String = ""
    @Published var selectedRoute: BusRouteInfo?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var routeList: [BusRouteInfo] = []
    @Published var selectedRouteStations: [RouteStationInfo] = []
    @Published var busLocations: [BusLocationInfo] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let busAPIService = BusAPIService.shared
    
    // 도시 코드 참고
    // 세종:12, 부산:21, 대구:22, 인천:23, 광주:24, 대전:25, 울산:26, 제주도:39
    
    // 버스 번호로 노선 검색
    func searchBusRoute() {
        guard !busNumber.isEmpty else {
            self.errorMessage = "버스 번호를 입력해주세요."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.routeList = []  // 기존 결과 초기화
        
        busAPIService.getBusRouteInfo(routeName: busNumber, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    if case NetworkError.emptyResponse = error {
                        self?.errorMessage = "검색 결과가 없습니다. 다른 버스 번호나 도시를 선택해 보세요."
                    } else {
                        self?.errorMessage = error.description
                    }
                }
            } receiveValue: { [weak self] routeList in
                self?.routeList = routeList
                
                if routeList.isEmpty {
                    self?.errorMessage = "검색 결과가 없습니다. 다른 버스 번호나 도시를 선택해 보세요."
                }
            }
            .store(in: &cancellables)
    }
    
    // 선택된 노선에 대한 정보 가져오기
    func selectRoute(_ route: BusRouteInfo) {
        self.selectedRoute = route
        self.fetchRouteStations(routeId: route.routeId)
        self.fetchBusLocations(routeId: route.routeId)
    }
    
    // 노선의 정류소 목록 가져오기
    private func fetchRouteStations(routeId: String) {
        self.isLoading = true
        
        busAPIService.getRouteStationList(routeId: routeId, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.description
                }
                self?.isLoading = false
            } receiveValue: { [weak self] stations in
                self?.selectedRouteStations = stations
            }
            .store(in: &cancellables)
    }
    
    // 노선의 버스 위치 정보 가져오기
    private func fetchBusLocations(routeId: String) {
        self.isLoading = true
        
        busAPIService.getBusLocationInfo(routeId: routeId, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.description
                }
                self?.isLoading = false
            } receiveValue: { [weak self] locations in
                self?.busLocations = locations
            }
            .store(in: &cancellables)
    }
    
    // 버스 위치 주기적으로 업데이트 (30초마다)
    func startLocationUpdates() {
        guard let routeId = selectedRoute?.routeId else { return }
        
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchBusLocations(routeId: routeId)
            }
            .store(in: &cancellables)
    }
    
    // 특정 정류소의 버스 도착 정보 가져오기
    func getBusArrivalInfo(stationId: String, completion: @escaping ([BusArrivalInfo]?, NetworkError?) -> Void) {
        busAPIService.getBusArrivalInfo(stationId: stationId, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { completionStatus in
                if case .failure(let error) = completionStatus {
                    completion(nil, error)
                }
            } receiveValue: { arrivalInfo in
                completion(arrivalInfo, nil)
            }
            .store(in: &cancellables)
    }
    
    // Cancellables 정리
    func cancelAllRequests() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
