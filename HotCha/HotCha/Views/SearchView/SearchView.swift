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
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager
    @StateObject private var viewModel = BusRouteViewModel()
    
    private func formatBusRoute(_ route: Bus_info_seoul) -> some View {
        return VStack(spacing: 0) {
            // 각 버스 항목
            HStack {
                // 버스 번호 및 타입 블록
                SearchBusUtil.CustomBusNoView(busNo: route.busRouteNm, routeType: route.routeType)
                
                // 버스 타입 필터링
                BusTypeLabelView(busNo: route.busRouteAbrv, routeType: route.routeType)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // 출발지-도착지 정보
            HStack {
                Text("\(route.stStationNm) ↔︎ \(route.edStationNm)")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray900"))
                Button(action: {
                    viewModel.fetchBusRoutes(searchStr: "")
                    saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
                }) {
                    Text("새로고침")
                }
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom)
            
            Rectangle()
                .foregroundStyle(Color("gray100"))
                .frame(height: 1)
            
        }
        .contentShape(Rectangle())
    }
    
    var body: some View {
        VStack {
            if textfiledValue.isEmpty {
                SearchHistoryView(modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)
            } else {
                // 필터링된 버스 노선들
                let filteredBusInfo = SearchBusSorting.filterBuses(buses: bus_info_seoul, searchText: textfiledValue)
                
                if filteredBusInfo.isEmpty {
                    // 검색 결과가 없을 때
                    VStack {
                        Spacer()
                        Text("검색 결과가 없습니다")
                            .font(.pretendard(.medium, size: 16))
                            .foregroundStyle(Color("gray500"))
                        Spacer()
                    }
                } else {
                    // 검색 결과가 있을 때
                    ScrollView {
                        LazyVStack {
                            ForEach(filteredBusInfo) { route in
                                NavigationLink(destination: AlarmSettingView(bus: .constant(route), cityCode: .constant(1), isBookmark: $isBookmark, type_name: $type_name, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)) {
                                    formatBusRoute(route)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    // 이 부분에서 dismiss 호출
                                    searchActivate = false
                                })
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            busStopSeoulViewModel.returnToRootView = false
        }
        .background(Color("gray50"))
    }
}
