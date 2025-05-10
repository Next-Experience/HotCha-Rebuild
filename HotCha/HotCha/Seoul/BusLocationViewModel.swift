//
//  BusLocationViewModel.swift
//  HotCha
//
//  Created by 문재윤 on 4/24/25.
//


//
//  BusLocationViewModel.swift
//  HotCha
//
//  Created by 문재윤 on 4/24/25.
//
import SwiftUI
import CoreLocation
import Combine

class BusLocationViewModel: ObservableObject {
    @Published var busPositions: [BusPosition] = []
    @Published var isRunning: Bool = false

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var busRouteId: String = "" {
        didSet {
            if isRunning {
                startFetching()
            }
        }
    }

    var consecutiveSameBusCount: Int = 0
    var lastSelectedBusId: String? = nil
    var selectedBusTimer: Timer? = nil

    // ✅ 위치 뷰모델 추가
    @ObservedObject var locationVM = LocationViewModel()

    init() {
        locationVM.requestPermission()
        locationVM.requestLocation()
        locationVM.requestalwaysPermission()
    }

    func startFetching() {
        stopFetching()
        
        guard !busRouteId.isEmpty else {
            print("버스 노선 ID 없음")
            return
        }

        isRunning = true
        fetchOnce()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchOnce()
        }
    }
 
    func stopFetching() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        selectedBusTimer?.invalidate()
        selectedBusTimer = nil
    }

    private func fetchOnce() {
        fetchSeoulBusLocation(busRouteId: busRouteId) { [weak self] positions, error in
            DispatchQueue.main.async {
                if let positions = positions {
                    self?.busPositions = positions
                    self?.evaluateNearestBus()
                } else if let error = error {
                    print("버스 데이터 가져오기 실패: \(error)")
                }
            }
        }
    }

    // ✅ 내 위치 기준으로 가장 가까운 버스를 판단
    private func evaluateNearestBus() {
        guard let currentLocation = locationVM.location else {
            print("현재 위치 없음")
            return
        }

        guard let nearestBus = nearestBus(from: currentLocation) else { return }

        if lastSelectedBusId == nearestBus.vehId {
            consecutiveSameBusCount += 1
        } else {
            consecutiveSameBusCount = 1
            lastSelectedBusId = nearestBus.vehId
        }

        if consecutiveSameBusCount >= 4 {
            startSendingSelectedBus(nearestBus)
        }
    }

    private func startSendingSelectedBus(_ bus: BusPosition) {
        selectedBusTimer?.invalidate()
        selectedBusTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.sendBusPosition(bus)
        }
    }

    private func sendBusPosition(_ bus: BusPosition) {
        print("선택된 버스: \(bus.vehId), 정류장 id: \(bus.nextStId) 위치: (\(bus.gpsY), \(bus.gpsX))")
    }

    func nearestBus(from location: CLLocation) -> BusPosition? {
        return busPositions.min(by: { lhs, rhs in
            let lhsLocation = CLLocation(latitude: lhs.gpsY, longitude: lhs.gpsX)
            let rhsLocation = CLLocation(latitude: rhs.gpsY, longitude: rhs.gpsX)
            return location.distance(from: lhsLocation) < location.distance(from: rhsLocation)
        })
    }
}
