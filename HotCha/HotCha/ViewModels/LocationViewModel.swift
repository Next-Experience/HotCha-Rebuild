//
//  LocationViewmodel.swift
//  HotCha
//
//  Created by 문재윤 on 2/10/25.

import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager() // 위치 관리 객체
    private let geocoder = CLGeocoder() // 지오코더 객체
    @Published var location: CLLocation? // 현재 위치 저장
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined // 권한 상태 저장
    @Published var administrativeArea: String? // 행정구역 저장
    @Published var address: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true  // ✅ 중요
        manager.pausesLocationUpdatesAutomatically = false // 중단 방지
    }
    
    // 권한 요청
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    func requestalwaysPermission() {
          manager.requestAlwaysAuthorization() // ✅ 백그라운드 위해 Always 권한 요청
      }
    
    // 위치 불러오기
    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
        } else {
            print("위치 서비스가 비활성화됨")
        }
    }
    
    
    // 위치 업데이트 실패 시 호출됨
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 정보를 가져오는 데 실패함: \(error.localizedDescription)")
    }
    
    // 권한 상태가 변경될 때 호출됨
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("권한 상태 변경")
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    // 위치 추적 시작
    func startTrackingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            manager.startUpdatingLocation()
        } else {
            print("위치 서비스 비활성화됨")
        }
    }

    // 위치 추적 종료
    func stopTrackingLocation() {
        manager.stopUpdatingLocation()
    }

    // 위치 업데이트 발생 시
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }

        DispatchQueue.main.async {
            self.location = currentLocation
        }

        geocoder.reverseGeocodeLocation(currentLocation) { [weak self] placemarks, error in
            if let error = error {
                print("지오코딩 실패: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                self?.administrativeArea = placemark.administrativeArea
                self?.address = placemark.subLocality ?? ""
            }
            print("위치 업데이트됨: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        }
    }
}
