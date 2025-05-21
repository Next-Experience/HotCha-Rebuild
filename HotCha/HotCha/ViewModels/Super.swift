//
//  Super.swift
//  HotCha
//
//  Created by 문재윤 on 5/6/25.
//

import Foundation
import CoreLocation
import Combine
import AVFoundation
import SwiftUI

class NearestBusViewModel: ObservableObject {
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
      var remainingStop: Int?
    @Published var busStops: [BusStop] = []
    @Published var isCalculating = false
    var locationviewModel = LocationViewModel()
    @Published var currBusStop: BusStop? = nil
    @Published var destinationStop: BusStop? = nil
    var busStops1: [BusStop] = []
    var currBusStop1: BusStop? = nil
    var destinationStop1: BusStop? = nil
    var isarrived: Int = 0
    
    var stationIdInput: String = "" // 도착 정류장
    var busRouteId: String = ""
    private var cancellables = Set<AnyCancellable>()
    private var lastSeq: Int? = nil
    var alarmFired = false // 알람 중복 방지
    
    @AppStorage("alarmStopDistanceFromDestination") var alarmStopDistanceFromDestination: Int = 2
    @AppStorage("soundToggle") var soundToggle: Bool = true
    @AppStorage("vibrationToggle") var vibrationToggle: Bool = true
    
    // 알람 종료뷰로 이동하기위한 트리거
    @Published var  navigateToAlarmEndView = false
    
    deinit {
    }
    
    
    func start(stationId: String, routeId: String, cityCode: String) {
        guard !isCalculating else {
            print("⚠️ 이미 실행 중")
            return
        }

        self.stationIdInput = stationId
        self.busRouteId = routeId
        self.isCalculating = true
        self.alarmFired = false
        self.lastSeq = nil
        self.currBusStop = nil
        locationviewModel.requestPermission()
        locationviewModel.startTrackingLocation()
        locationviewModel.requestalwaysPermission()

        print("🚀 정류장 목록 패치 시작")

        let fetchCompletion: ([BusStop], String?) -> Void = { [weak self] stops, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ 정류장 로딩 실패: \(error)")
                return
            }

            DispatchQueue.main.async {
                self.busStops = stops
            }
            self.busStops1 = stops
            print("✅ 정류장 \(stops.count)개 로딩 완료")

            for i in stops {
                print(i.stationNm, "----")
                print(i.station, "----")
            }

            guard let matchedStop = stops.first(where: { String($0.station) == stationId }) else {
                print("⚠️ stationId와 일치하는 정류장을 찾을 수 없습니다")
                return
            }

            DispatchQueue.main.async {
                self.destinationStop1 = matchedStop
            }
            self.destinationStop1 = matchedStop

            if let alarmStop = stops.first(where: { $0.seq == matchedStop.seq - self.alarmStopDistanceFromDestination }) {
                print("🎯 도착 정류장 매칭 완료: \(matchedStop.stationNm) (seq: \(matchedStop.seq))")

                if let start = self.findStartingStation(from: self.locationviewModel.location ?? CLLocation(), stations: BusStopList_Items(item: stops), destinationSeq: matchedStop.seq) {
                    DispatchQueue.main.async {
                        self.currBusStop = start
                    }
                    self.currBusStop1 = start
                    self.lastSeq = start.seq
                    print("🏁 시작 정류장 설정됨: \(start.stationNm) (seq: \(start.seq))")

                    LiveActivityManager.shared.startLiveActivity(
                        title: "핫챠",
                        description: routeId,
                        progress: 0.9,
                        busname: start.busRouteNm,
                        currentStop: start.stationNm,
                        stopsRemaining: matchedStop.seq - start.seq,
                        alarmstop: alarmStop.stationNm,
                        destinationStation: matchedStop.stationNm,
                        Updatetime: formattedTime(from: Date())
                    )
                }
            }

            self.subscribeToLocationUpdates()
        }

        // ✅ 여기서 바로 분기
        if cityCode == "1" {
            HotCha.fetchBusStations(routeId: routeId, completion: fetchCompletion)
        } else {
            HotCha.fetchBusStation(cityCode: cityCode, routeId: routeId, completion: fetchCompletion)
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
        cancellables.removeAll()
        locationviewModel.stopTrackingLocation()
        LiveActivityManager.shared.endLiveActivity()
        print("🛑 추적 중단")
    }
    
    private func subscribeToLocationUpdates() {
        locationviewModel.$location
            .compactMap { $0 }
            .sink { [weak self] currentLocation in
                self?.handleLocationUpdate(currentLocation)
            }
            .store(in: &cancellables)
    }
    

    private func handleLocationUpdate(_ currentLocation: CLLocation) {
        guard isCalculating else { return }
        guard let destinationStop1 = destinationStop1,
              let currStop1 = currBusStop1 else {
            print("❗️현재 정류장 또는 도착 정류장 정보 없음")
            return
        }
        print("여기서 위치 업데이트!!!!!!----------")
        let busStopList = BusStopList_Items(item: busStops)
        

        if let result = getCurrentOrNextBusStation(
            currentLocation: currentLocation,
            stations: busStopList,
            currentStop: currStop1
        ) {
            DispatchQueue.main.async {
                self.currBusStop = currStop1
            }
            let (nextStationId, _) = result
            if result.arrived == 0 {
                self.currBusStop1 = result.station
                self.lastSeq = result.station.seq
                DispatchQueue.main.async {
                    self.isarrived = result.arrived
                }
                let remaining = destinationStop1.seq - currStop1.seq
                self.remainingStop = remaining
                print("📍 도착! 새로운 현재 정류장: \(result.station.stationNm), 남은 정류장: \(remaining)")
                if let alarmStop = busStops.first(where: { $0.seq == destinationStop1.seq - self.alarmStopDistanceFromDestination }) {
                    
                    
                    LiveActivityManager.shared.updateLiveActivity(
                        progress: 1.0,
                        currentStop: result.station.stationNm,
                        stopsRemaining: remaining,
                        alarmstop: alarmStop.stationNm,
                        destinationStation: destinationStop1.stationNm,
                        Updatetime: formattedTime(from: Date())
                        
                    )
                }
                if remaining == alarmStopDistanceFromDestination && !alarmFired && isarrived == 1 {
                    triggerAlarm()
                    alarmFired = true
                }
                if remaining == 0 && !alarmFired && isarrived == 1 {
                    triggerAlarm()
                    alarmFired = true
                }
                
            } else {
                let remaining = destinationStop1.seq - currStop1.seq
                self.remainingStop = remaining
                self.isarrived = result.arrived
                print("----라액------")
                if let alarmStop = busStops.first(where: { $0.seq == destinationStop1.seq - self.alarmStopDistanceFromDestination }) {
                    LiveActivityManager.shared.updateLiveActivity(
                        progress: 1.0,
                        currentStop: result.station.stationNm,
                        stopsRemaining: remaining,
                        alarmstop: alarmStop.stationNm,
                        destinationStation: destinationStop1.stationNm,
                        Updatetime: formattedTime(from: Date())
                        
                    )
                }
                if remaining == alarmStopDistanceFromDestination && !alarmFired && isarrived == 1 {
                    triggerAlarm()
                    alarmFired = true
                }
                if remaining == 0 && !alarmFired && isarrived == 1 {
                    triggerAlarm()
                    alarmFired = true
                }
            }
        }
    }
    
    private func triggerAlarm() {
        print("🚨 알람 트리거됨! 정류장 도착 임박")
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.navigateToAlarmEndView = true
        }

        
        startAlarmToggle(
            isOn: true,
            title: "핫챠! 내릴 준비를 해주세요",
            body: "도착까지 \(String(alarmStopDistanceFromDestination))정류장 남았어요!",
            useSound: soundToggle,
            useVibration: vibrationToggle
        )
        
        
    }
    
    // 기존 함수 재사용
    func findStartingStation(
        from location: CLLocation,
        stations: BusStopList_Items,
        destinationSeq: Int
    ) -> BusStop? {
        print("첫번째 정류장 찾기 시작 !!")
        let sortedByDistance = stations.item.sorted {
            let loc1 = CLLocation(latitude: $0.gpsY, longitude: $0.gpsX)
            let loc2 = CLLocation(latitude: $1.gpsY, longitude: $1.gpsX)
            return location.distance(from: loc1) < location.distance(from: loc2)
        }
        let closestTwo = Array(sortedByDistance.prefix(2))
        print("가장 가까운  두 정류장 !\(closestTwo[0].stationNm),,,,,,\(closestTwo[1].stationNm)")
        return closestTwo.min {
            abs($0.seq - destinationSeq) < abs($1.seq - destinationSeq)
        }
    }
    
    func getCurrentOrNextBusStation(
        currentLocation: CLLocation,
        stations: BusStopList_Items,
        currentStop: BusStop
    ) -> (station: BusStop, arrived: Int)? {
        
        let detectionRadius: Double = 200.0
        let busStops = stations.item.sorted(by: { $0.seq < $1.seq })
        
        guard let currentIndex = busStops.firstIndex(where: { $0.station == currentStop.station }) else {
            print("❗️현재 정류장을 리스트에서 찾을 수 없습니다")
            return nil
        }
        
        let nextIndex = currentIndex + 1
        guard nextIndex < busStops.count else {
            print("✅ 마지막 정류장 도착")
            return nil
        }
        
        let nextStop = busStops[nextIndex]
        let nextLocation = CLLocation(latitude: nextStop.gpsY, longitude: nextStop.gpsX)
        let currentStop_Location = CLLocation(latitude: currentStop.gpsY, longitude: currentStop.gpsX)
        let distance = currentLocation.distance(from: nextLocation)
        let distance_current = currentLocation.distance(from: currentStop_Location)
        
        print("📡 다음 정류장: \(nextStop.stationNm) 거리: \(Int(distance))m")
        if distance_current <= 50 {
            return (currentStop, 0) // 도착 처리
        }
        
        if distance <= detectionRadius {
            return (nextStop, 0) // 도착 처리
        }
        
        return (nextStop, 1)
    }
}

