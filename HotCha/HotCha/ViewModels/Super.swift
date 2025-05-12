//
//  Super.swift
//  HotCha
//
//  Created by 문재윤 on 5/6/25.
//

import Foundation
import CoreLocation
import Combine

class NearestBusViewModel: ObservableObject {
    @Published var remainingStop: Int?
    @Published var busStops: [BusStop] = []
    @Published var isCalculating = false
    var locationviewModel = LocationViewModel()
    @Published var currBusStop: BusStop? = nil

    private var timer: AnyCancellable?
//    private let busRouteId = "100100324"
    private let viewModel = BusLocationViewModel()

    var stationIdInput: String = ""// 외부에서 주입 가능
    var busRouteId: String = ""
    @State private var isGpsAlert = false
    
    @AppStorage("alarmStopDistanceFromDestination") var alarmStopDistanceFromDestination: Int = 2
    @AppStorage("soundToggle") var soundToggle: Bool = true
    @AppStorage("vibrationToggle") var vibrationToggle: Bool = true


    deinit {
        stop()
        viewModel.stopFetching()
    }

//    func start() {
//        guard !isCalculating else {
//            print("⚠️ 이미 실행 중")
//            return
//        }
//        isCalculating = true
//        LiveActivityManager.shared.startLiveActivity(title: "핫챠" , description: "불러오는 중", stationName: stationIdInput, initialProgress: 99, currentStop: "불러오는 중",stopsRemaining: 999, destinationStation: stationIdInput, Updatetime: formattedTime(from: Date()))
//        fetchBusStopsIfNeeded()
//    }
    func start(stationId: String, routeId: String) {
        
        guard !isCalculating else {
            print("⚠️ 이미 실행 중")
            return
        }

        self.stationIdInput = stationId
        self.busRouteId = routeId
        self.viewModel.busRouteId = routeId
        self.viewModel.startFetching()
        if let loc = locationviewModel.location {
            print("위도: \(loc.coordinate.latitude)")
            print("경도: \(loc.coordinate.longitude)")
        }

        isCalculating = true
        locationviewModel.requestPermission()
        locationviewModel.startTrackingLocation()
        locationviewModel.requestalwaysPermission()

        LiveActivityManager.shared.startLiveActivity(
            title: "핫챠",
            description: routeId,
            stationName: stationId,
            initialProgress: 99,
            currentStop: routeId,
            stopsRemaining: 999,
            destinationStation: stationId,
            Updatetime: formattedTime(from: Date())
        )
        print("--패치 버스스탑--")
        fetchBusStopsIfNeeded(stationId: stationId, routeId: routeId)
        print("--패치 버스스탑완료--")
    }
    func stop() {
        isCalculating = false
        LiveActivityManager.shared.endLiveActivity()
        timer?.cancel()
        timer = nil
    }

    private func fetchBusStopsIfNeeded(stationId: String, routeId: String) {
        print("🚀 fetchBusStations 시작: \(routeId)")
        fetchBusStations(routeId: routeId) { [weak self] stops, error in
            print("ee")
            guard let self = self else { return }
            print("🚀 fetchBusStations 시작: \(routeId)")
            if let error = error {
                print("❌ 정류장 로딩 실패: \(error)")
                return
            }
            if stops.isEmpty {
                print("🚨 stops 비어있음!")
            }

            self.busStops = stops
            print("✅ 정류장 \(stops.count)개 로딩됨")
            for i in busStops {
                print(i.stationNm,"----")
                print(i.station,"----")
            }
            self.startLoop(stationId: stationId, routeId: routeId)
        }
        print("dho dkseod")
    }



    func startLoop(stationId: String, routeId: String) {
           guard isCalculating else {
               print("루프 끝 (isCalculating이 false)")
               return
           }

           print("🚀 루프 시작")
           // Timer publisher 생성
           timer = Timer
               .publish(every: 1.0, on: .main, in: .common)
               .autoconnect()
               .sink { [weak self] _ in
                   guard let self = self else { return }
                   guard self.isCalculating else {
                       print("🛑 계산 중단됨")
                       self.timer?.cancel()
                       self.timer = nil
                       return
                   }
                   let destinationStop = busStops.first { String($0.station) == stationId }
                   let alarmSeq = destinationStop?.seq ?? 1 -  alarmStopDistanceFromDestination
                   let alarmDestination = busStops.first { $0.seq == alarmSeq}
                   let targetLocation = CLLocation(latitude: alarmDestination?.gpsY ?? 10, longitude: alarmDestination?.gpsX ?? 10)
                   

                   if !isGpsAlert {
                       let triggered = checkProximity(currentLocation: locationviewModel.location, targetLocation: targetLocation)
                       if triggered {
                           isGpsAlert = true
                           startAlarmToggle(
                                   isOn: true,
                                   title: "핫챠! 내릴 준비를 해주세요",
                                   body: "도착까지 \(String(alarmStopDistanceFromDestination))정거장 남았어요!",
                                   useSound: soundToggle,
                                   useVibration: vibrationToggle
                               )

                       }
                       else {
                           print("멀었다")
                       }
                       print("targetLocation: \(targetLocation)xzzzzzzzzz")
                       
                   }
                   

//                   LiveActivityManager.shared.updateLiveActivity(
//                       progress: 1.0,  // 진행률을 항상 1로 설정
//                       currentStop: "targetLocation: \(targetLocation)xzzzzzzzzz",
//                       stopsRemaining: 20000726,
//                       destinationStation: "\(locationviewModel.location)",
//                       Updatetime: formattedTime(from: Date())
//                   )

                   LiveActivityManager.shared.updateLiveActivity(
                       progress: 1.0,  // 진행률을 항상 1로 설정
                       currentStop: "targetLocation: \(targetLocation)xzzzzzzzzz",
                       stopsRemaining: 20000726,
                       destinationStation: "\(locationviewModel.location)",
                       Updatetime: formattedTime(from: Date())
                   )

                   
                   self.updateRemainingStops(stationId: stationId, routeId: routeId)
                   print("루프 진행중")
               }
       }

    private func updateRemainingStops(stationId: String, routeId: String) {
        @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."

        guard let nearestBus = viewModel.nearestBus(from: viewModel.locationVM.location ?? CLLocation()) else {
            currBusStop = nil
            print("❌ 가까운 버스 없음")
            return
        }

        currBusStop = busStops.first { String($0.station) == nearestBus.nextStId }
        let destinationStop = busStops.first { String($0.station) == stationIdInput }

        if let current = currBusStop, let destination = destinationStop {
            remainingStop = destination.seq - current.seq
            
            print(destination.seq, current.seq, "왜 이래")

            print("✅ 남은 정류장: \(remainingStop ?? -1)")
            
            if alarmStopDistanceFromDestination == remainingStop {
                startAlarmToggle(
                    isOn: true,
                    title: "핫챠! 내릴 준비를 해주세요",
                    body: "도착까지 \(String(alarmStopDistanceFromDestination))정거장 남았어요!",
                    useSound: soundToggle,
                    useVibration: vibrationToggle
                )

            }

            
            LiveActivityManager.shared.updateLiveActivity(
                progress: 1.0,  // 진행률을 항상 1로 설정
                currentStop: current.stationNm,
                stopsRemaining: Int(remainingStop ?? 0),
                destinationStation: destination.stationNm,
                Updatetime: formattedTime(from: Date())
            )
            if remainingStop ?? 0 >= 0 {
                remainingStops = "\(abs(remainingStop ?? -1))정거장 전"
            } else {
                remainingStops = "\(abs(remainingStop ?? -1))정거장 후"
            }
            
        } else {
            if currBusStop == nil {
                print("↳ 현재 정류장 정보 없음")
                remainingStops = "불러오는 중..."
            }
            if destinationStop == nil { print("↳ 도착 정류장 정보 없음") }
        }
    }

    func nearestBus() -> BusPosition? {
        return viewModel.nearestBus(from: viewModel.locationVM.location ?? CLLocation())
    }
}


import SwiftUI

struct NearestBus3View: View {
    @StateObject private var vm = NearestBusViewModel()

    @State private var stationInput = "161000611"
        @State private var routeInput = "100100324"

    var body: some View {
        VStack(spacing: 20) {
            Text("가장 가까운 버스")
                .font(.largeTitle)
                .padding(.top)

            TextField("정류장 ID 입력", text: $stationInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("시작") {
                    vm.stationIdInput = stationInput
                       vm.busRouteId = routeInput
                 
                }
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)

                Button("중단") {
                    vm.stop()
                }
                .padding()
                .background(Color.red.opacity(0.2))
                .cornerRadius(10)
            }

            if let bus = vm.nearestBus() {
                VStack {
                    Text("버스 ID: \(bus.vehId)")
                    Text(String(format: "위도: %.5f", bus.gpsY))
                    Text(String(format: "경도: %.5f", bus.gpsX))
                    Text("다음 정류장 ID: \(bus.nextStId)")
                }
                .font(.title2)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            } else {
                Text("가까운 버스를 찾는 중...")
                    .foregroundColor(.gray)
            }

            if let stops = vm.remainingStop {
                Text("남은 정류장 수: \(stops)")
                    .font(.headline)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}


// 🔔 거리 계산 및 알람 트리거 함수
func checkProximity(currentLocation: CLLocation?, targetLocation: CLLocation, threshold: Double = 500.0) -> Bool {
    guard let current = currentLocation else { return false }
    
    let distance = current.distance(from: targetLocation)
    print("현재 거리: \(Int(distance))m")
    
    if distance <= threshold {
        print("🔔 알림: 목표 지점 도달!")
        return true
    }
    
    return false
}


//func startCheckingDistance() {
//    Task {
//        let result = await checkDistance(
//            toX: targetLongitude,
//            toY: targetLatitude,
//            locationViewModel: locationViewModel
//        )
//        if result == 1 {
//            await MainActor.run {
//                isArrived = true
//            }
//        }
//    }
//}
