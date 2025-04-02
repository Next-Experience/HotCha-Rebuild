//
//  SeoulBusStopViewModel.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//

// 서울 버스스탑을 가지고 옴

import SwiftUI
import Foundation

class BusStopSeoulViewModel: ObservableObject {
    @Published var busStations: [BusStop] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Route ID를 직접 인자로 받아 데이터를 가져오는 메서드
    func fetchBusStations(routeid: String) {
        guard !routeid.isEmpty else {
            errorMessage = "Route ID를 입력하세요."
            return
        }

        isLoading = true
        errorMessage = nil

        HotCha.fetchBusStations(routeId: routeid) { [weak self] stations, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error
                } else {
                    self?.busStations = stations
                }
            }
        }
    }
}
