//
//  LocationViewmodel.swift
//  HotCha
//
//  Created by 문재윤 on 2/10/25.

import CoreLocation
import Combine
import MapKit

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager() // 위치 관리 객체
    @Published var location: CLLocation? // 현재 위치 저장
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined // 권한 상태 저장
    /// "서울특별시" · "경상남도 양산시" 처럼 시까지 적은 지금 지역. 아직 모르면 nil 이다.
    @Published private(set) var regionName: String?
    private var lastGeocodedLocation: CLLocation?
    private var geocoding: MKReverseGeocodingRequest?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 20 // 50미터 이상 이동 시에만 업데이트
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
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

        // 주소는 멀리 움직였을 때만 다시 묻는다. 위치가 올 때마다 물으면 금방 한도에 걸린다.
        if let last = lastGeocodedLocation, currentLocation.distance(from: last) < 1_000 { return }
        guard geocoding?.isLoading != true, let request = MKReverseGeocodingRequest(location: currentLocation) else {
            return
        }
        geocoding = request
        request.getMapItems { [weak self] items, _ in
            // 실패하면 기록하지 않는다. 다음 위치에서 다시 묻는다.
            // cityWithContext 는 "서울특별시" · "경상남도 양산시" 처럼 특별시 · 광역시는 한 번만 적어 준다.
            guard let name = items?.first?.addressRepresentations?.cityWithContext else { return }
            self?.lastGeocodedLocation = currentLocation
            self?.regionName = name
        }
    }
}
