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
    }
    
    // 권한 요청
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // 위치 불러오기
    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
        } else {
            print("위치 서비스가 비활성화됨")
        }
    }
    
    // 위치 불러와졌을 때
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        // 위치 정보를 받은 후, 지오코딩을 통해 행정구역 정보를 얻음
        geocoder.reverseGeocodeLocation(currentLocation) { [weak self] placemarks, error in
            if let error = error {
                print("지오코딩 실패: \(error.localizedDescription)")
                return
            }
            
            // 첫 번째 플래이스마크에서 행정구역 정보 추출
            if let placemark = placemarks?.first {
                self?.administrativeArea = placemark.administrativeArea
                self?.address = placemark.subLocality ?? ""
//             thoroughfare // 다른 주소 정보
//             subThoroughfare // 다른 주소 정보
            }
            print("ㅋㅋㅋㅋㅋㅋ")
        }
        
        DispatchQueue.main.async {
            self.location = currentLocation
        }
        
        manager.stopUpdatingLocation()
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
}
