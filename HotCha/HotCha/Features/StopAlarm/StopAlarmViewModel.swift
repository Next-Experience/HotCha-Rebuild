//
//  StopAlarmViewModel.swift
//  HotCha
//
//  노선 없이 정류장 하나만 골라, 그 정류장에 가까워지면 울리는 알람.
//

import Combine
import CoreLocation
import Foundation
import HotChaKit
import SwiftUI

final class StopAlarmViewModel: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var didFire = false
    /// 알람이 울리고 있다. 확인하면 꺼지고 안내는 이어진다.
    @Published private(set) var isRinging = false
    /// 목적지 정류장까지 남은 거리(m). 위치를 아직 못 받았으면 nil
    @Published private(set) var distance: CLLocationDistance?


    private let locationViewModel = LocationViewModel()
    private var cancellables = Set<AnyCancellable>()
    /// 안내 중인 정류장. 안내 중이 아니면 nil 이다.
    @Published private(set) var runningStop: BusStopRecord?
    private var target: BusStopRecord?
    private(set) var radius: CLLocationDistance = 500
    private var lastReportedDistance: Int?
    private var startedAt: Date?
    /// 안내를 시작했을 때 정류장까지의 거리. 이동 거리를 재는 기준이다.
    private var startDistance: CLLocationDistance?
    /// 기차역 안내일 때만 있다. 언제 울릴지는 HotChaKit 이 정한다(터널에서 위치가 끊기는 경우까지).
    private var stationApproach: StationApproach?
    /// 위치가 끊겨도 시간이 흐른 것을 규칙에 알려 주는 타이머. 기차역 안내 동안만 돈다.
    private var signalTimer: Timer?

    init() {
        // 알람을 시작하기 전에도 "현재 위치에서 몇 m" 를 보여주기 위해 위치를 받는다.
        locationViewModel.$location
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)
        // 시스템 알람 화면에서 알람을 끄면 앱의 알람 화면도 닫는다. 안내는 계속된다.
        NotificationCenter.default.publisher(for: .systemAlarmStopped)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.isRinging = false }
            .store(in: &cancellables)
    }

    /// 정류장 화면이 열려 있는 동안 "현재 위치에서 몇 m" 를 보여 주려고 위치를 받는다.
    func beginPreview() {
        locationViewModel.requestPermission()
        locationViewModel.requestLocation()
    }

    /// 화면을 닫으면 위치 받기를 멈춘다. 안내 중이면 계속 받는다.
    func endPreview() {
        guard !isRunning else { return }
        locationViewModel.stopTrackingLocation()
        target = nil
        distance = nil
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
        runningStop = stop
        self.radius = radius
        didFire = false
        isRunning = true
        lastReportedDistance = nil
        startedAt = Date()
        startDistance = distance
        // 알람은 AlarmKit 시스템 알람이다. 처음이면 여기서 권한을 묻는다.
        Task { @MainActor in AlarmRinger.shared.requestAuthorizationIfNeeded() }

        stationApproach =
            stop.isTrainStation
            ? StationApproach(
                destination: GeoPoint(latitude: stop.latitude, longitude: stop.longitude), radius: radius)
            : nil
        locationViewModel.useTrainTracking(stop.isTrainStation)
        locationViewModel.requestalwaysPermission()
        locationViewModel.startTrackingLocation()
        if stationApproach != nil {
            signalTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                self?.checkSignal()
            }
        }

        LiveActivityController.shared.start(
            attributes: HotChaActivityAttributes(
                kind: stop.isTrainStation ? .train : .stop,
                busNumber: "",
                destination: stop.name,
                alarmPoint: "\(Self.format(radius)) 전",
                imageName: "HotChaClayBusStop"
            ),
            state: liveState(meters: distance.map { Int($0) })
        )

        if let location = locationViewModel.location {
            handle(location)
        }
    }

    /// 알람만 끈다. 안내(위치 추적)는 계속된다.
    func silence() {
        Task { @MainActor in AlarmRinger.shared.stop() }
        isRinging = false
    }

    func stop() {
        guard isRunning else { return }
        silence()
        // 안내를 끝낼 때 이용 기록에 남긴다.
        if let runningStop {
            StopAlarmHistory.add(runningStop)
            // 처음 거리에서 지금 거리를 뺀 만큼 가까워졌다. 직선 거리라 실제 길보다 짧게 잡힌다.
            let approached = max((startDistance ?? 0) - (distance ?? startDistance ?? 0), 0)
            JourneyLog.add(
                Journey(kind: .stop, startedAt: startedAt ?? Date(), endedAt: Date(), meters: approached))
        }
        isRunning = false
        didFire = false
        runningStop = nil
        stationApproach = nil
        signalTimer?.invalidate()
        signalTimer = nil
        locationViewModel.stopTrackingLocation()
        locationViewModel.useTrainTracking(false)
        LiveActivityController.shared.end()
    }

    private func handle(_ location: CLLocation) {
        guard let target else { return }
        let meters = location.distance(from: target.location)
        distance = meters
        guard isRunning else { return }
        if startDistance == nil { startDistance = meters }

        if var approach = stationApproach {
            let update = approach.update(
                location: GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                accuracy: location.horizontalAccuracy, at: location.timestamp)
            stationApproach = approach
            // 흐린 위치(터널 안 기지국 위치)는 거리 표시에도 쓰지 않는다. 마지막으로 믿을 만했던 거리를 둔다.
            distance = update.distance
            if update.shouldFireAlarm { ring(target) }
        } else if meters <= radius && !didFire {
            ring(target)
        }
        report()
    }

    /// 위치가 오지 않는 동안에도 몇 초마다 부른다. 터널에서 끊긴 시간을 규칙이 재게 한다.
    private func checkSignal() {
        guard isRunning, let target, var approach = stationApproach else { return }
        let update = approach.tick(now: Date())
        stationApproach = approach
        if update.shouldFireAlarm {
            ring(target)
            report()
        }
    }

    private func ring(_ target: BusStopRecord) {
        guard !didFire else { return }
        didFire = true
        isRinging = true
        let title = "\(target.name)에서 내려요"
        Task { @MainActor in AlarmRinger.shared.ring(title: title) }
    }

    /// 50m(기차역은 100m) 단위로 달라질 때만 갱신한다. 알람이 울린 것은 controller 가 상태 차이로 알아챈다.
    private func report() {
        guard let distance else { return }
        let step = stationApproach == nil ? 50.0 : 100.0
        let bucket = Int(distance / step) * Int(step)
        if bucket != lastReportedDistance || didFire {
            lastReportedDistance = bucket
            LiveActivityController.shared.update(liveState(meters: bucket))
        }
    }

    private func liveState(meters: Int?) -> HotChaActivityAttributes.ContentState {
        HotChaActivityAttributes.ContentState(
            remainingStops: nil,
            remainingMeters: meters,
            currentStop: "",
            hasAlarmFired: didFire
        )
    }

    static func format(_ meters: CLLocationDistance) -> String {
        guard meters >= 1000 else { return "\(Int(meters))m" }
        let km = (meters / 100).rounded() / 10
        return km == km.rounded() ? "\(Int(km))km" : String(format: "%.1fkm", km)
    }
}
