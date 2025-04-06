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
    
    private func getRouteTypeString(_ routeType: String) -> String {
        switch routeType {
        case "1": return "공항"
        case "2": return "마을"
        case "3": return "간선"
        case "4": return "지선"
        case "5": return "순환"
        case "6": return "광역"
        case "7": return "인천"
        case "8": return "경기"
        case "9": return "폐지"
        case "0": return "공용"
        default: return "일반"
        }
    }
    
    private func formatBusRoute(_ route: Bus_info_seoul) -> some View {
        let routeTypeStr = getRouteTypeString(route.routeType)
        
        return VStack(spacing: 0) {
            // 각 버스 항목
            HStack(spacing: 10) {
                // 버스 번호 및 타입 블록
                BookmarkBusNoView(busNo: route.busRouteAbrv, route_type: routeTypeStr)
                
                // 노선 정보
                Text("\(route.busRouteNm)")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray900"))
                
                Spacer()
                
                // 경기 버튼과 같은 추가 정보가 필요할 경우
                if route.routeType == "8" { // 경기 버스인 경우
                    Text("경기")
                        .font(.pretendard(.regular, size: 12))
                        .foregroundStyle(Color("gray300"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color("gray100"))
                        .cornerRadius(4)
                }
            }
            .padding(.top, 16)
            
            // 출발지-도착지 정보
            HStack {
                Text("\(route.stStationNm) ↔︎ \(route.edStationNm)")
                    .font(.pretendard(.regular, size: 14))
                    .foregroundStyle(Color("gray700"))
                Spacer()
            }
            .padding(.vertical, 6)
            
            Divider()
                .foregroundStyle(Color("gray100"))
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // 전체 영역을 탭 가능하게
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if textfiledValue.isEmpty {
                SearchHistoryView()
            } else {
                // 필터링된 버스 노선들
                let filteredBusInfo = bus_info_seoul.filter { bus in
                    bus.busRouteNm.contains(textfiledValue) ||
                    bus.busRouteAbrv.contains(textfiledValue)
                }
                
                if filteredBusInfo.isEmpty {
                    // 검색 결과가 없을 때
                    VStack(spacing: 16) {
                        Spacer()
                        Text("검색 결과가 없습니다")
                            .font(.pretendard(.medium, size: 16))
                            .foregroundStyle(Color("gray500"))
                        Spacer()
                    }
                } else {
                    // 검색 결과가 있을 때
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredBusInfo) { route in
                                NavigationLink(destination: AlarmSettingView(bus: route, cityCode: 1)) {
                                    formatBusRoute(route)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .background(Color.white)
                }
            }
        }
        .background(Color("gray50"))
    }
}
