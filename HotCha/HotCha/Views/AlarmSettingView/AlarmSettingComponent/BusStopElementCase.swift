//
//  Untitled.swift
//  HotCha
//
//  Created by Yeji Seo on 2/9/25.
//

import SwiftUI

/// 정류장 Element의 경우의 수
enum BusStopElementCase {
    case ableStop // 일반 정류장
    case disableStop // 지나온 정류장
    case currentStop // 현재 위치한 정류장
    case alarmStop // 알람이 울릴 정류장
    case destinationStop // 목적지 정류장
    
    
    var text_color: Color {
        switch self {
        case .ableStop:
            return .gray100
        case .disableStop:
            return .gray150.opacity(0.4)
        case .currentStop, .alarmStop, .destinationStop:
            return .mainpurple
        }
    }
    
    var line_color: Color {
        switch self {
        case .disableStop:
            return .gray150.opacity(0.4)
        default:
            return .gray150
        }
    }
    
    var outer_circle_size: CGFloat {
        switch self {
        case .alarmStop, .destinationStop:
            return 22
        default:
            return 16
        }
    }
    
    var outer_circle_color: Color {
        switch self {
        case .disableStop:
            return .gray400
        case .currentStop, .alarmStop, .destinationStop:
            return .mainpurple
        default:
            return .gray150
        }
    }
    
    var background_color: Color {
        switch self {
        case .alarmStop, .destinationStop:
            return .purpleOpacity10
        default:
            return .clear
        }
    }
    
    // 현재 위치 정류장
    var is_shadow: Bool {
        switch self {
        case .currentStop:
            return true
        default:
            return false
        }
    }
    
    var trailing_icon: Image? {
        switch self {
        case .alarmStop:
            return Image(systemName: "bell")
        case .destinationStop:
            return Image("map_pin")
        default:
            return nil
        }
    }
}


//#Preview {
//    AlarmSettingView()
//}
