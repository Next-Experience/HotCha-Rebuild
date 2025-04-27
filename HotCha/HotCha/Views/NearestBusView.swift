
//
//  NearestBusView.swift
//  HotCha
//
//  Created by 문재윤 on 4/24/25.
//


import SwiftUI
import CoreLocation


struct NearestBusView: View {
    @StateObject private var viewModel = BusLocationViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("가장 가까운 버스")
                .font(.largeTitle)
                .padding(.top)

            if let nearestBus = viewModel.nearestBus(from: viewModel.locationVM.location ?? CLLocation()) {
                VStack {
                    Text("버스 ID: \(nearestBus.vehId)")
                    Text(String(format: "위도: %.5f", nearestBus.gpsY))
                    Text(String(format: "경도: %.5f", nearestBus.gpsX))
                }
                .font(.title2)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            } else {
                Text("가까운 버스 정보를 불러오는 중...")
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .onAppear {
            viewModel.busRouteId = "100100414" // 여기에 원하는 버스 노선 ID 입력
            viewModel.startFetching()
        }
        .onDisappear {
            viewModel.stopFetching()
        }
        .padding()
    }
}
#Preview {
    NearestBusView()
}
