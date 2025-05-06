//
//  SuperBusViewModel.swift
//  HotCha
//
//  Created by 문재윤 on 5/6/25.
//

import SwiftUI
import CoreLocation

class NearestBusViewModel: ObservableObject {
    @Published var nearestBus: BusPosition?
    @Published var remainingStops: Int?
    
    private(set) var routeId: String = ""
    private(set) var destinationStationId: String = ""
    
    private var busStops: [BusStop] = []
    private var isCalculating = false

    private var timer: Timer?
    let locationVM = LocationViewModel()
    private let busFetcher = BusLocationViewModel()

    func configure(routeId: String, destinationStationId: String) {
        self.routeId = routeId
        self.destinationStationId = destinationStationId
    }

    func start() {
        busFetcher.busRouteId = routeId
        busFetcher.startFetching()
        fetchBusStops()
    }

    func stop() {
        busFetcher.stopFetching()
        stopCalculating()
    }

    private func fetchBusStops() {
        fetchBusStations(routeId: routeId) { [weak self] stops, error in
            if let error = error {
                print("❌ 정류장 정보 로드 실패: \(error)")
                return
            }
            self?.busStops = stops
            self?.startCalculating()
        }
    }

    private func startCalculating() {
        guard !isCalculating else { return }
        
        isCalculating = true
//        LiveActivityManager.shared.startLiveActivity(title: "알 수 없는 알람" , description: "dd", stationName: "dd", initialProgress: 99, currentStop: "dd", stopsRemaining: 0, Updatetime: "dd")
        calculateLoop()
    }

    private func stopCalculating() {
        isCalculating = false
//        LiveActivityManager.shared.endLiveActivity()
    }

    private func calculateLoop() {
        guard isCalculating else {
            print("🛑 계산 중단")
            return
        }

        updateNearestBus()
        updateRemainingStops()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.calculateLoop()
        }
    }

    private func updateNearestBus() {
        guard let location = locationVM.location else { return }
        self.nearestBus = busFetcher.nearestBus(from: location)
    }

    private func updateRemainingStops() {
        guard let bus = nearestBus else { return }

        let currentStop = busStops.first { String($0.station) == bus.nextStId }
        let destinationStop = busStops.first { String($0.station) == destinationStationId }

        if let current = currentStop, let destination = destinationStop {
            remainingStops = destination.seq - current.seq
            print("✅ 남은 정류장 수: \(remainingStops ?? -1)")
//            LiveActivityManager.shared.updateLiveActivity(
//                progress: 1.0,  // 진행률을 항상 1로 설정
//                currentStop: "",
//                stopsRemaining: 9999,
//                Updatetime: formattedTime(from: Date())
//            )
        } else {
            print("❌ 정류장 찾기 실패")
        }
    }
}


