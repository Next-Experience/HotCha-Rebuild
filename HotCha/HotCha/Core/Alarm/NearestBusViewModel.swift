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
    private var routeType: String?
    /// 정류장을 따라가고 알람 시점을 정하는 규칙은 HotChaKit 에 있다. 여기서는 결과를 화면·알림으로 옮기기만 한다.
    private var tracker: RouteTracker?

    func start(stationId: String, routeId: String, cityCode: String, busNumber: String? = nil, routeType: String? = nil) {
        guard !isCalculating else { return }

        self.stationIdInput = stationId
        self.busRouteId = routeId
        self.busNumber = busNumber
        self.routeType = routeType
        self.isCalculating = true
        self.tracker = nil
        self.currBusStop = nil
        self.destinationStop = nil
        self.remainingStop = nil
        locationviewModel.requestPermission()
        locationviewModel.startTrackingLocation()
        locationviewModel.requestalwaysPermission()

        BusAPI.fetchRouteStops(cityCode: cityCode, routeId: routeId) { [weak self] stops, error in
            DispatchQueue.main.async {
                guard let self, self.isCalculating else { return }

                let sorted = stops.sorted { $0.seq < $1.seq }
                guard error == nil,
                      let destinationIndex = sorted.firstIndex(where: { $0.station == stationId }),
                      let tracker = RouteTracker(
                          stops: sorted.map { GeoPoint(latitude: $0.gpsY, longitude: $0.gpsX) },
                          destinationIndex: destinationIndex,
                          alarmStopsBefore: self.alarmStopDistanceFromDestination
                      ) else {
                    // 다시 시작할 수 있도록 상태를 되돌린다.
                    self.isCalculating = false
                    self.locationviewModel.stopTrackingLocation()
                    return
                }

                self.busStops = sorted
                self.destinationStop = sorted[destinationIndex]
                self.tracker = tracker
                self.subscribeToLocationUpdates()
            }
        }
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
        LiveActivityManager.shared.endLiveActivity()
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
        let alarmStopName = busStops[tracker.alarmStopIndex].stationNm

        if update.isFirstFix {
            let displayBusName = (current.busRouteNm == "알 수 없음" && busNumber != nil) ? busNumber! : current.busRouteNm
            LiveActivityManager.shared.startLiveActivity(
                title: "핫챠",
                description: busRouteId,
                progress: 0.9,
                busname: displayBusName,
                routeType: routeType,
                currentStop: current.stationNm,
                stopsRemaining: update.remaining,
                alarmstop: alarmStopName,
                destinationStation: destination.stationNm,
                Updatetime: formattedTime(from: Date())
            )
        } else {
            LiveActivityManager.shared.updateLiveActivity(
                progress: 1.0,
                currentStop: current.stationNm,
                stopsRemaining: update.remaining,
                alarmstop: alarmStopName,
                destinationStation: destination.stationNm,
                Updatetime: formattedTime(from: Date())
            )
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
