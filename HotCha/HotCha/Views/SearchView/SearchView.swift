//
//  SearchView.swift
//  HotCha
//
//  Created by 문재윤 on 2/24/25.
//
import SwiftUI
import SwiftData

struct SearchView: View {
    @Binding var textfiledValue: String
    @Binding var searchActivate: Bool
    @Environment(\.modelContext) private var modelContext
    @Query var bus_info_seoul: [Bus_info_seoul]


    var body: some View {
        if textfiledValue.isEmpty {
            SearchHistoryView()
        } else {
            // 필터링된 버스 노선들
            let filteredBusInfo = bus_info_seoul.filter { bus in
                bus.busRouteNm.contains(textfiledValue)
            }

            List(filteredBusInfo) { route in
//                NavigationLink(destination: AlarmSettingView(bus: route, cityCode: 1)){
                    VStack(alignment: .leading) {
                        Text("\(route.busRouteNm) - \(route.corpNm)").font(.headline)
                    }
                }
//            }
        }
    }
}
