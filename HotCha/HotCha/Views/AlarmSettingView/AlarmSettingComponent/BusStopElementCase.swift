//
//  Untitled.swift
//  HotCha
//
//  Created by Yeji Seo on 2/9/25.
//

import SwiftUI

struct BusStopElementCase: OptionSet, Hashable {
    let rawValue: Int

    static let ableStop        = BusStopElementCase(rawValue: 1 << 0)
    static let disableStop     = BusStopElementCase(rawValue: 1 << 1)
    static let currentStop     = BusStopElementCase(rawValue: 1 << 2)
    static let alarmStop       = BusStopElementCase(rawValue: 1 << 3)
    static let destinationStop = BusStopElementCase(rawValue: 1 << 4)
    static let filteredStop    = BusStopElementCase(rawValue: 1 << 5)
    
    static let bothCurrentBusWithAlarm: BusStopElementCase = [.currentStop, .alarmStop]
    static let bothDisableBusWithAlarm: BusStopElementCase = [.disableStop, .alarmStop]
    static let bothCurrentBusWithDest: BusStopElementCase = [.currentStop, .destinationStop]
}

extension BusStopElementCase {
    var text_color: Color {
        if contains(.currentStop) || contains(.alarmStop) || contains(.destinationStop) || contains(.filteredStop) {
            return .mainpurple
        } else if contains(.disableStop) {
            return .gray150.opacity(0.4)
        } else {
            return .gray100
        }
    }
    
    var line_color: Color {
        if contains(.alarmStop){
            return .gray150
        } else if contains(.disableStop) {
            return .gray150.opacity(0.4)
        } else {
            return .gray150
        }
    }
    
    var outer_circle_size: CGFloat {
        if contains(.alarmStop) || contains(.destinationStop) {
            return 36
        } else if contains(.filteredStop) {
            return 22
        } else {
            return 16
        }
    }
    
    var outer_circle_color: Color {
        if contains(.currentStop) && contains(.alarmStop) || contains(.currentStop) && contains(.destinationStop) || contains(.disableStop) && contains(.alarmStop){
            return .gray150
        }
        else if contains(.disableStop) {
            return .gray400
        } else if contains(.currentStop) {
            return .mainpurple
        } else {
            return .gray150
        }
    }
    
    var background_color: Color {
        if contains(.alarmStop) || contains(.destinationStop) || contains(.filteredStop) {
            return .purpleOpacity10
        } else {
            return .clear
        }
    }
    
    var leading_icon: Image? {
        if contains(.destinationStop) {
            return Image("map_pin")
        } else if contains(.alarmStop) || (contains(.currentStop) && contains(.alarmStop)){
            return Image("bell")
        } else {
            return nil
        }
    }
    
    var move_icon: Image? {
        if contains(.alarmStop) {
            return Image("code")
        } else {
            return nil
        }
    }
}


/// 정류장 Element의 경우의 수
//enum BusStopElementCase {
//    case ableStop // 일반 정류장
//    case disableStop // 지나온 정류장
//    case currentStop // 현재 위치한 정류장
//    case alarmStop // 알람이 울릴 정류장
//    case destinationStop // 목적지 정류장
//    case filteredStop // 필터링된 정류장
//    
//    
//    var text_color: Color {
//        switch self {
//        case .ableStop:
//            return .gray100
//        case .disableStop:
//            return .gray150.opacity(0.4)
//        case .currentStop, .alarmStop, .destinationStop, .filteredStop:
//            return .mainpurple
//        }
//    }
//    
//    var line_color: Color {
//        switch self {
//        case .disableStop:
//            return .gray150.opacity(0.4)
//        default:
//            return .gray150
//        }
//    }
//    
//    var outer_circle_size: CGFloat {
//        switch self {
//        case .alarmStop, .destinationStop:
//            return 36
//        case  .filteredStop:
//            return 22
//        default:
//            return 16
//        }
//    }
//    
//    var outer_circle_color: Color {
//        switch self {
//        case .disableStop:
//            return .gray400
//        case .currentStop:
//            return .mainpurple
////        case .alarmStop, .destinationStop:
////            return .gray150
//        default:
//            return .gray150
//        }
//    }
//    
//    var background_color: Color {
//        switch self {
//        case .alarmStop, .destinationStop, .filteredStop:
//            return .purpleOpacity10
//        default:
//            return .clear
//        }
//    }
//    
//    // 현재 위치 정류장
//    var is_shadow: Bool {
//        switch self {
//        case .currentStop:
//            return true
//        default:
//            return false
//        }
//    }
//    
//    var leading_icon: Image? {
//        switch self {
//        case .alarmStop:
//            return Image("bell")
//        case .destinationStop:
//            return Image("map_pin")
//        default:
//            return nil
//        }
//    }
//    
//    var move_icon: Image? {
//        switch self {
//        case .alarmStop:
//            return Image("code")
//        default:
//            return nil
//        }
//    }
//}


//#Preview {
//    AlarmSettingView()
//}
