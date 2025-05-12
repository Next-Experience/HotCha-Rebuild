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


//    private func startLoop(stationId: String, routeId: String) {
//        func loop() {
//            // 매번 실행될 때마다 최신 상태의 isCalculating을 확인
//            guard self.isCalculating else {
//                print("🛑 계산 중단됨")
//                return
//            }
//            
//            self.updateRemainingStops(stationId: stationId, routeId: routeId)
//            
//            // 1초 후 루프 계속 돌도록 설정
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                // 루프가 진행 중일 때만 다시 호출
//                if self.isCalculating {
//                    loop() // 재귀 호출로 루프 계속 실행
//                } else {
//                    print("🛑 루프 종료")
//                }
//            }
//            
//            print("루프 진행중")
//        }
//
//        if self.isCalculating {
//            loop()
//            print("🚀 루프 시작")
//        } else {
//            print("루프 끝")
//        }
//    }
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
                   LiveActivityManager.shared.updateLiveActivity(
                       progress: 1.0,  // 진행률을 항상 1로 설정
                       currentStop: "ee",
                       stopsRemaining: 3,
                       destinationStation: "dd",
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


