//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 4/28/25.
//
import SwiftUI
import Foundation
import CoreLocation

// 거리 체크 함수
func checkDistance(toX: Double, toY: Double, locationViewModel: LocationViewModel) async -> Int {
    // 목표 위치
    let targetLocation = CLLocation(latitude: toY, longitude: toX)

    while true {
           // 현재 위치 가져오기
           guard let currentLocation = locationViewModel.location else {
               print("현재 위치를 가져오는 중입니다...")
               // 위치가 아직 업데이트 안됐으면 1초 쉬고 다시 시도
               try? await Task.sleep(nanoseconds: 1_000_000_000)
               continue
           }
           
        
        // 거리 계산 (미터 단위)
        let distance = currentLocation.distance(from: targetLocation)
        print("현재 거리: \(distance)미터")
        
        // 거리 체크
        if distance <= 100 {
            print("도착")
            return 1
        } else if distance > 1000 {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10초
            print("distance > 1000")
        } else if distance > 500 {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5초
            print("distance > 500")
        } else if distance > 200 {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
            print("distance > 200")
        } else {
            // 200m 이하면 0.5초 주기로 더 자주 체크할 수도 있음 (선택사항)
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}

