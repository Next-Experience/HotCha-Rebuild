//
//  BusTypeLabel.swift
//  HotCha
//
//  Created by 문호 on 4/8/25.
//

import Foundation
import SwiftUI

struct BusTypeLabelView: View {
    let busNo: String
    let routeType: String
    
    var body: some View {
        Group {
            if busNo.hasPrefix("G") {
                Text("경기도 급행 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "1" {
                Text("서울시 공항 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "2" {
                Text("마을 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "3" {
                Text("간선 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "4" {
                Text("지선 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "5" {
                Text("순환 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "6" {
                Text("광역 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "7" {
                Text("인천 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "8" {
                Text("경기 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "9" {
                Text("폐지 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else if routeType == "0" {
                Text("폐지 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
            else {
                Text("일반 버스")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
            }
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        BusTypeLabelView(busNo: "G1000", routeType: "8")
        BusTypeLabelView(busNo: "500", routeType: "3")
        BusTypeLabelView(busNo: "5005", routeType: "1")
    }
    .padding()
}
