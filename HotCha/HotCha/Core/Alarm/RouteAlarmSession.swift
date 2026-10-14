//
//  RouteAlarmSession.swift
//  HotCha
//
//  노선 알람 한 건의 상태. 화면을 벗어나도 안내가 이어지도록 앱 전체가 하나를 나눠 쓴다.
//

import Combine
import CoreLocation
import Foundation
import HotChaKit
import SwiftData

final class RouteAlarmSession: ObservableObject {
    @Published private(set) var bus: Bus_info_seoul?
    @Published private(set) var stops: [BusStop] = []
    @Published var destinationIndex: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var loadFailed = false

    private let engine = NearestBusViewModel()
    private var startedAt: Date?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 엔진이 바뀌면 이 세션을 보는 화면도 다시 그린다.
        engine.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        // 시스템 알람 화면에서 알람을 끄면 앱의 알람 화면도 닫는다. 안내는 계속된다.
        NotificationCenter.default.publisher(for: .systemAlarmStopped)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.alarmIsRinging = false }
            .store(in: &cancellables)
    }

    // MARK: - 읽기

    var isRunning: Bool { engine.isCalculating }
    /// 목적지까지 남은 정류장 수. 첫 위치를 받기 전에는 nil 이다.
    var remainingStops: Int? { engine.remainingStop }
    var currentStop: BusStop? { engine.currBusStop }
    /// 알람이 한 번 울렸고 아직 안내를 끝내지 않았다.
    var hasAlarmFired: Bool { isRunning && engine.alarmHasFired }

    /// 안내를 시작하고 첫 위치를 받았을 때의 정류장 자리(탄 정류장). 그 전에는 nil 이다.
    var boardedIndex: Int? { isRunning ? engine.startStopIndex : nil }

    /// 지금 있는 정류장의 자리. 첫 위치를 받기 전에는 nil 이다.
    var currentIndex: Int? {
        currentStop.flatMap { stop in stops.firstIndex { $0.station == stop.station && $0.seq == stop.seq } }
    }

    /// 지금 시작하면 어느 정류장에서 출발하는 것으로 잡힐지 미리 본다. 지도에 「탑승」으로 보여 주는 용도다.
    /// 규칙은 안내 중과 같은 RouteTracker 의 출발 정류장 규칙이다.
    func boardingIndex(near location: CLLocation) -> Int? {
        guard let destinationIndex,
            var tracker = RouteTracker(
                stops: stops.map { GeoPoint(latitude: $0.gpsY, longitude: $0.gpsX) },
                destinationIndex: destinationIndex,
                alarmStopsBefore: 0
            )
        else { return nil }
        return tracker.update(
            location: GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        ).currentIndex
    }

    var destinationStop: BusStop? {
        destinationIndex.flatMap { stops.indices.contains($0) ? stops[$0] : nil }
    }

    /// 알람이 울릴 정류장. 안내 전에는 설정한 N정류장 전으로 미리 보여 준다.
    var alarmStop: BusStop? {
        if let index = engine.alarmStopIndex, stops.indices.contains(index) {
            return stops[index]
        }
        guard let destinationIndex else { return nil }
        return stops[max(destinationIndex - engine.alarmStopDistanceFromDestination, 0)]
    }

    var alarmIsRinging: Bool {
        get { engine.navigateToAlarmEndView }
        set { engine.navigateToAlarmEndView = newValue }
    }

    /// 이 노선의 안내가 진행 중인가
    func isRunning(for bus: Bus_info_seoul) -> Bool {
        isRunning && self.bus?.busRouteId == bus.busRouteId && self.bus?.city_code == bus.city_code
    }

    /// 지도에서 거의 겹쳐 보이는 같은 이름의 정류장들(눌린 것 포함, 노선 순서대로).
    /// 대부분 길 양쪽의 상행 · 하행이다. 둘 사이가 이만큼보다 가까우면 지도에서 손가락으로 가려 누를 수 없다.
    static func overlappingStops(at index: Int, in stops: [BusStop], within meters: Double = 120) -> [Int] {
        guard stops.indices.contains(index) else { return [] }
        let here = CLLocation(latitude: stops[index].gpsY, longitude: stops[index].gpsX)
        return stops.indices.filter { other in
            let stop = stops[other]
            return isSelectable(stop) && stop.stationNm == stops[index].stationNm
                && CLLocation(latitude: stop.gpsY, longitude: stop.gpsX).distance(from: here) <= meters
        }
    }

    /// 이 정류장 다음에 서는 곳. 이름이 같은 정류장을 버스가 가는 방향으로 가려 보여 줄 때 쓴다.
    func nextStopName(after index: Int) -> String? {
        stops.indices.contains(index + 1) ? stops[index + 1].stationNm : nil
    }

    /// 고를 수 없는 정류장. 이름에 미정차·가상이 붙은 곳은 버스가 서지 않는다.
    static func isSelectable(_ stop: BusStop) -> Bool {
        !stop.stationNm.contains("미정차") && !stop.stationNm.contains("가상")
    }

    // MARK: - 동작

    /// 노선의 정류장 목록을 받는다. 안내 중인 노선이면 아무것도 하지 않는다.
    func load(_ bus: Bus_info_seoul, startingAt destinationId: String? = nil, completion: (() -> Void)? = nil) {
        guard !isRunning else { return }
        self.bus = bus
        stops = []
        destinationIndex = nil
        isLoading = true
        loadFailed = false

        BusAPI.fetchRouteStops(cityCode: bus.city_code, routeId: bus.busRouteId) { [weak self] fetched, error in
            DispatchQueue.main.async {
                guard let self, self.bus?.busRouteId == bus.busRouteId, !self.isRunning else { return }
                self.isLoading = false
                guard error == nil, !fetched.isEmpty else {
                    self.loadFailed = true
                    return
                }
                self.stops = fetched.sorted { $0.seq < $1.seq }
                if let destinationId {
                    self.destinationIndex = self.stops.firstIndex { $0.station == destinationId }
                }
                completion?()
            }
        }
    }

    /// 고른 도착 정류장으로 안내를 시작한다.
    @discardableResult
    func start() -> Bool {
        guard let bus, let destinationIndex else { return false }
        // 알람은 AlarmKit 시스템 알람이다. 처음이면 여기서 권한을 묻는다.
        Task { @MainActor in AlarmRinger.shared.requestAuthorizationIfNeeded() }
        startedAt = Date()
        return engine.start(
            stops: stops,
            destinationIndex: destinationIndex,
            routeId: bus.busRouteId,
            busNumber: bus.busRouteNm,
            routeType: bus.routeType,
            busImage: BusArt.imageName(for: bus)
        )
    }

    /// 울리는 알람만 끈다. 안내는 계속된다.
    func silence() {
        Task { @MainActor in AlarmRinger.shared.stop() }
        alarmIsRinging = false
    }

    /// 안내를 끝내고 이용 기록에 남긴다.
    func finish(in context: ModelContext) {
        if let bus, let destination = destinationStop, isRunning {
            context.insert(Usage_history(
                bus: BusFavoriteHistory(from: bus),
                route_id: bus.busRouteId,
                city_code: bus.city_code,
                destination_stop_id: destination.station,
                destination_stop_name: destination.stationNm,
                bus_no: bus.busRouteNm,
                route_type: bus.routeType,
                get_off_timestamp: Date(),
                operator_name: bus.corpNm.isEmpty ? nil : bus.corpNm,
                operator_no: nil,
                vehicle_no: ""
            ))
            JourneyLog.add(Journey(
                kind: .bus,
                startedAt: startedAt ?? Date(),
                endedAt: Date(),
                meters: engine.travelledMeters
            ))
        }
        engine.stop()
        alarmIsRinging = false
        bus = nil
        stops = []
        destinationIndex = nil
    }

    /// 안내를 시작하지 않고 화면을 떠날 때 고른 것을 비운다.
    func discardIfIdle() {
        guard !isRunning else { return }
        bus = nil
        stops = []
        destinationIndex = nil
        isLoading = false
        loadFailed = false
    }
}
