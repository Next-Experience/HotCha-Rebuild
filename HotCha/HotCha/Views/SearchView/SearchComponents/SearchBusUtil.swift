//
//  SearchUtilView.swift
//  HotCha
//
//  Created by 문호 on 4/8/25.
//

import SwiftUI

struct SearchBusUtil {
    static func getRouteTypeString(_ routeType: String) -> String {
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
        
        // 노선 유형에 따른 색상 반환
        static func getColorForRouteType(_ routeType: String) -> Color {
            switch routeType {
            case "1": // 공항
                return Color("bluec")
            case "2": // 마을
                return Color("olivec")
            case "3": // 간선
                return Color("skybluec")
            case "4": // 지선
                return Color("greenc")
            case "5": // 순환
                return Color("purplec")
            case "6": // 광역
                return Color("orangec")
            case "7": // 인천
                return Color("bluec")
            case "8": // 경기
                return Color("brownc")
            default:
                return Color("bluec")
            }
        }
        
        // 커스텀 버스 번호 뷰
        static func CustomBusNoView(busNo: String, routeType: String) -> some View {
            let color = getColorForRouteType(routeType)
            
            return Text(busNo)
                .font(.pretendard(.semibold, size: 14))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .cornerRadius(4)
        }
    }
