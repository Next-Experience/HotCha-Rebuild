//
//  AlarmSettingElement.swift
//  HotCha
//
//  Created by Yeji Seo on 3/4/25.
//

import SwiftUI

class AlarmModalViewModel: ObservableObject {
    @Published var modalState: AlarmSettingModalElementCase = .alarmWait
    @Published var bus: Bus_info_seoul?
    @Published var cityCode: Int?
    
}


enum AlarmSettingModalElementCase {
    case alarmWait // 알람 기다리는 상태
    case alarmStart // 알람세팅 화면 첫 화면, 정류장 선택 후 시작 버튼
    case alarmSearch // 도착 정류장 검색 화면
    case alertStopsSmall // 몇 정류장 전, 알람종료 버튼 표시
    case alertStopsMedium // 위의 Small 에서 알람울릴 정류장/도착 정류장 선택 표시, 기본 버스 정보
    case alertStopsLarge // 위의 Medium에서 알람 세팅 추가(소리, 진동)
    
    
    var alarmStatusSettingSection: some View {
        switch self {
        case .alertStopsLarge:
            return AnyView(AlertSettingSection())
        default:
            return AnyView(EmptyView())
        }
    }
    
    var alertBusInfoSection: some View {
        switch self {
        case .alertStopsMedium, .alertStopsLarge:
            return AnyView(
                VStack{
                    BusStopInfoSection(isBookmark: .constant(false))
                    BusStopDestinationSection()
                })
        default:
            return AnyView(EmptyView())
        }
    }
    
    var alarmSettingMainView: some View {
        switch self {
        case .alarmWait, .alarmStart, .alarmSearch:
            return AnyView(BusStopSearchView())
        case .alertStopsSmall, .alertStopsMedium, .alertStopsLarge:
            return AnyView(AlarmStatusView())
        }
    }
    
    var alarmSettingSearchBottomView: some View {
        switch self {
        case .alarmWait:
            return AnyView(MainPurpleAlarmButton(isInfoFilled: false))
        case .alarmSearch:
            return AnyView(AlarmSearchScrollButtonSection())
        default:
            return AnyView(EmptyView())
        }
    }
}
