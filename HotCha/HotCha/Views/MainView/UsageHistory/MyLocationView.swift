//
//  my_location.swift
//  HotCha
//
//  Created by 문재윤 on 2/13/25.
//

import SwiftUI
import CoreLocation

struct MyLocationView: View {
    @StateObject private var viewModel = LocationViewModel()
    
    var body: some View {
        HStack {
            // 행정구역 정보 표시
            if let administrativeArea = viewModel.administrativeArea, let address = viewModel.address
                {
                Image("mappin")
                    .padding(.leading, 20)
                Text("\(administrativeArea) \(address)")
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color("gray150"))

            } else {
                Image(systemName: "location.slash.fill")
                    .padding(.leading, 20)
                Text("위치를 확인할 수 없음")
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color("gray150"))            }

        }
        .onAppear {
    //        viewModel.requestPermission()  // 앱 실행 시 권한 요청
            print("----")
            viewModel.requestLocation()
        }
    }
}
