//
//  BusStopViewModel.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation
import Combine

class BusStopViewModel: ObservableObject {
    @Published var cityCode: String = ""
    @Published var stationName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var busStops: [BusStopInfo] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let busAPIService = BusAPIService.shared
    
    // 정류소 이름으로 검색
    func searchBusStop() {
        guard !stationName.isEmpty else {
            self.errorMessage = "정류소 이름을 입력해주세요."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        self.busStops = []  // 기존 결과 초기화
        
        busAPIService.getBusStopInfo(stationName: stationName, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    if case NetworkError.emptyResponse = error {
                        self?.errorMessage = "검색 결과가 없습니다. 다른 정류소 이름이나 도시를 선택해 보세요."
                    } else {
                        self?.errorMessage = error.description
                    }
                }
            } receiveValue: { [weak self] busStops in
                self?.busStops = busStops
                
                if busStops.isEmpty {
                    self?.errorMessage = "검색 결과가 없습니다. 다른 정류소 이름이나 도시를 선택해 보세요."
                }
            }
            .store(in: &cancellables)
    }
    
    // 정류소 ID로 버스 도착 정보 조회
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
    
    func cancelAllRequests() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
