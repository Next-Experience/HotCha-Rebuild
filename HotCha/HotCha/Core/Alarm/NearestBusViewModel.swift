//
//  NearestBusViewModel.swift
//  HotCha
//
//  Created by 문재윤 on 5/6/25.
//
//  노선 알람 엔진: 내 위치로 지금 몇 번째 정류장인지 따라가다가
//  목적지 N정류장 전에 알람을 울린다.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI
import HotChaKit

class NearestBusViewModel: ObservableObject {
    @Published var remainingStop: Int?
    @Published var busStops: [BusStop] = []
    @Published var isCalculating = false
    @Published var currBusStop: BusStop? = nil
    @Published var destinationStop: BusStop? = nil
    // 알람 종료뷰로 이동하기위한 트리거
    @Published var navigateToAlarmEndView = false

    var locationviewModel = LocationViewModel()
    var stationIdInput: String = "" // 도착 정류장
    var busRouteId: String = ""

    @AppStorage("alarmStopDistanceFromDestination") var alarmStopDistanceFromDestination: Int = 2
    @AppStorage("soundToggle") var soundToggle: Bool = true
    @AppStorage("vibrationToggle") var vibrationToggle: Bool = true

    private var cancellables = Set<AnyCancellable>()
    private var busNumber: String?
    private var busImage = "HotChaClayBus"
    private var routeType: String?
    /// 정류장을 따라가고 알람 시점을 정하는 규칙은 HotChaKit 에 있다. 여기서는 결과를 화면·알림으로 옮기기만 한다.
    private var tracker: RouteTracker?
    /// 첫 위치를 받았을 때의 정류장 자리. 이동 거리를 재는 기준이다.
    private(set) var startStopIndex: Int?

    /// 이미 받아 둔 정류장 목록으로 안내를 시작한다. 정류장은 노선 순서대로여야 한다.
    /// 시작하지 못하면(목적지가 목록 밖) false 를 돌려준다.
    @discardableResult
    func start(
        stops: [BusStop],
        destinationIndex: Int,
        routeId: String,
        busNumber: String? = nil,
        routeType: String? = nil,
        busImage: String = "HotChaClayBus"
    ) -> Bool {
        guard !isCalculating,
              let tracker = RouteTracker(
                  stops: stops.map { GeoPoint(latitude: $0.gpsY, longitude: $0.gpsX) },
                  destinationIndex: destinationIndex,
                  alarmStopsBefore: alarmStopDistanceFromDestination
              ) else {
            return false
        }

        self.stationIdInput = stops[destinationIndex].station
        self.busRouteId = routeId
        self.busNumber = busNumber
        self.routeType = routeType
        self.busImage = busImage
        self.isCalculating = true
        self.currBusStop = nil
        self.remainingStop = nil
        self.busStops = stops
        self.destinationStop = stops[destinationIndex]
        self.tracker = tracker
        self.startStopIndex = nil

        locationviewModel.requestPermission()
        locationviewModel.startTrackingLocation()
        locationviewModel.requestalwaysPermission()
        subscribeToLocationUpdates()
        return true
    }

    /// 안내를 시작한 정류장부터 지금 정류장까지 노선을 따라 온 거리(m)
    var travelledMeters: Double {
        guard let start = startStopIndex, let current = tracker?.currentIndex else { return 0 }
        return (tracker?.stops ?? []).pathLength(from: start, to: current)
    }

    /// 이번 안내에서 알람이 이미 울렸는가
    var alarmHasFired: Bool {
        tracker?.alarmFired ?? false
    }

    /// 알람 정류장의 자리. 안내 중이 아니면 nil 이다.
    var alarmStopIndex: Int? {
        tracker?.alarmStopIndex
    }

    func stop() {
        startAlarmToggle(
            isOn: false,
            title: "",
            body: "",
            useSound: false,
            useVibration: false
        )

        isCalculating = false
        tracker = nil
        cancellables.removeAll()
        locationviewModel.stopTrackingLocation()
        LiveActivityController.shared.end()
    }

    private func subscribeToLocationUpdates() {
        cancellables.removeAll()
        locationviewModel.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentLocation in
                self?.handleLocationUpdate(currentLocation)
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ currentLocation: CLLocation) {
        guard isCalculating, var tracker, let destination = destinationStop else { return }

        let update = tracker.update(location: GeoPoint(
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude
        ))
        self.tracker = tracker

        let current = busStops[update.currentIndex]
        if currBusStop?.id != current.id {
            currBusStop = current
        }
        remainingStop = update.remaining
        // 이번 갱신에서 울리는 것까지 포함해, 알람이 이미 울린 뒤인지 Live Activity 에 알린다.
        let state = HotChaActivityAttributes.ContentState(
            remainingStops: update.remaining,
            remainingMeters: nil,
            currentStop: current.stationNm,
            hasAlarmFired: tracker.alarmFired
        )

        if update.isFirstFix {
            startStopIndex = update.currentIndex
            let displayBusName = (current.busRouteNm == "알 수 없음" && busNumber != nil) ? busNumber! : current.busRouteNm
            LiveActivityController.shared.start(
                attributes: HotChaActivityAttributes(
                    kind: .route,
                    busNumber: displayBusName,
                    destination: destination.stationNm,
                    alarmPoint: busStops[tracker.alarmStopIndex].stationNm,
                    imageName: busImage
                ),
                state: state
            )
        } else {
            LiveActivityController.shared.update(state)
        }

        if update.shouldFireAlarm {
            triggerAlarm(remaining: update.remaining)
        }
    }

    private func triggerAlarm(remaining: Int) {
        navigateToAlarmEndView = true

        startAlarmToggle(
            isOn: true,
            title: "핫챠! 내릴 준비를 해주세요",
            body: remaining > 0 ? "도착까지 \(remaining)정류장 남았어요!" : "곧 도착 정류장이에요!",
            useSound: soundToggle,
            useVibration: vibrationToggle
        )
    }
}
