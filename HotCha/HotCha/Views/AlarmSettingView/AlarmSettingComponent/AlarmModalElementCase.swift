//
//  AlarmSettingElement.swift
//  HotCha
//
//  Created by Yeji Seo on 3/4/25.
//

import SwiftUI

enum AlarmModalElementCase {
    case alarmStart // 알람세팅 화면 첫 화면, 정류장 선택 후 시작 버튼
    case alarmSearch // 도착 정류장 검색 화면
    case alertStopsSmall // 몇 정거장 전, 알람종료 버튼 표시
    case alertStopsMedium // 위의 Small 에서 알람울릴 정류장/도착 정류장 선택 표시, 기본 버스 정보
    case alertStopsLarge // 위의 Medium에서 알람 세팅 추가(소리, 진동)
    
    
    var is_star: Bool {
        switch self {
        case .alertStopsLarge:
            return true
        default:
            return false
        }
    }
    
    var fractionDetent: CGFloat {
        switch self {
        case .alertStopsSmall:
            return 0.1
        case .alertStopsMedium:
            return 0.4
        case .alertStopsLarge:
            return 0.99
        default:
            return 0.32
        }
    }

    
    
}


#Preview {
    AlarmSettingView()
}

