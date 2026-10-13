//
//  StopAlarmViewModel.swift
//  HotCha
//
//  노선 없이 정류장 하나만 골라, 그 정류장에 가까워지면 울리는 알람.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

final class StopAlarmViewModel: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var didFire = false
    /// 목적지 정류장까지 남은 거리(m). 위치를 아직 못 받았으면 nil
    @Published private(set) var distance: CLLocationDistance?

    @AppStorage("soundToggle") private var soundToggle: Bool = true
    @AppStorage("vibrationToggle") private var vibrationToggle: Bool = true

    private let locationViewModel = LocationViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var target: BusStopRecord?
    private var radius: CLLocationDistance = 500
    private var lastReportedDistance: Int?

    init() {
        // 알람을 시작하기 전에도 "현재 위치에서 몇 m" 를 보여주기 위해 위치를 받는다.
        locationViewModel.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)
        locationViewModel.requestPermission()
        locationViewModel.requestLocation()
    }

    deinit {
        locationViewModel.stopTrackingLocation()
    }

    /// 지도에서 고른 정류장이 바뀌면 거리 기준도 바꾼다. (알람 중에는 바꾸지 않는다)
    func select(_ stop: BusStopRecord?) {
        guard !isRunning else { return }
        target = stop
        distance = stop.flatMap { stop in
            locationViewModel.location.map { $0.distance(from: stop.location) }
        }
    }

    func start(stop: BusStopRecord, radius: CLLocationDistance) {
        guard !isRunning else { return }
        target = stop
        self.radius = radius
        didFire = false
        isRunning = true
        lastReportedDistance = nil

        locationViewModel.requestalwaysPermission()
        locationViewModel.startTrackingLocation()
        RecentStops.add(stop)

        LiveActivityManager.shared.startLiveActivity(
            title: "핫챠",
            description: stop.id,
            progress: 0,
            busname: "정류장",
            currentStop: "이동 중",
            stopsRemaining: 0,
            alarmstop: "\(Self.format(radius)) 전",
            destinationStation: stop.name,
            Updatetime: formattedTime(from: Date()),
            distanceMeters: distance.map { Int($0) }
        )

        if let location = locationViewModel.location {
            handle(location)
        }
    }

    /// 알람 소리만 끈다. 안내(위치 추적)는 계속된다.
    func silence() {
        startAlarmToggle(isOn: false, title: "", body: "", useSound: false, useVibration: false)
    }

    func stop() {
        guard isRunning else { return }
        silence()
        isRunning = false
        didFire = false
        locationViewModel.stopTrackingLocation()
        LiveActivityManager.shared.endLiveActivity()
    }

    private func handle(_ location: CLLocation) {
        guard let target else { return }
        let meters = location.distance(from: target.location)
        distance = meters
        guard isRunning else { return }

        // Live Activity 는 50m 단위로 달라질 때만 갱신한다.
        let bucket = Int(meters / 50) * 50
        if bucket != lastReportedDistance {
            lastReportedDistance = bucket
            LiveActivityManager.shared.updateLiveActivity(
                progress: 0,
                currentStop: "이동 중",
                stopsRemaining: 0,
                alarmstop: "\(Self.format(radius)) 전",
                destinationStation: target.name,
                Updatetime: formattedTime(from: Date()),
                distanceMeters: Int(meters)
            )
        }

        if meters <= radius && !didFire {
            didFire = true
            startAlarmToggle(
                isOn: true,
                title: "핫챠! 내릴 준비를 해주세요",
                body: "\(target.name)까지 약 \(Self.format(meters)) 남았어요!",
                useSound: soundToggle,
                useVibration: vibrationToggle
            )
        }
    }

    static func format(_ meters: CLLocationDistance) -> String {
        guard meters >= 1000 else { return "\(Int(meters))m" }
        let km = (meters / 100).rounded() / 10
        return km == km.rounded() ? "\(Int(km))km" : String(format: "%.1fkm", km)
    }
}

/// 최근에 알람을 맞춘 정류장 (가벼운 목록이라 UserDefaults 에 둔다)
enum RecentStops {
    private static let key = "recentAlarmStops"
    private static let maxCount = 8

    static func load() -> [BusStopRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stops = try? JSONDecoder().decode([BusStopRecord].self, from: data) else {
            return []
        }
        return stops
    }

    static func add(_ stop: BusStopRecord) {
        var stops = load().filter { $0.id != stop.id }
        stops.insert(stop, at: 0)
        if let data = try? JSONEncoder().encode(Array(stops.prefix(maxCount))) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
