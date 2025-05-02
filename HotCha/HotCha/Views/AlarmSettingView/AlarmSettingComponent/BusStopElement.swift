//
//  BusStopElement.swift
//  HotCha
//
//  Created by Yeji Seo on 2/7/25.
//
// AlarmSettingView에서 버스 정류장 리스트를 나타낼 때 사용할 컴포넌트

import SwiftUI

/// 버스 정류장 리스트 한 칸
struct BusStopElement: View {
    let stopCase: BusStopElementCase
    @State var busStop: BusStop?
    
    var body: some View {
        HStack(spacing: 0){
            ZStack {
                // 정류장 이미지 표시 영역
                ZStack {
                    VStack (spacing: 0) {
                        // 첫번째 정류장이 아니면 일반, 이면 line이 투명색
                        BusStopLine(line_color: (busStop?.isFirstStop != true) ? stopCase.line_color: .clear)
                            .padding(0)
                        
                        // 마지막 정류장이 아니면 일반, 이면 line이 투명색
                        BusStopLine(line_color: (busStop?.isLastStop != true) ? stopCase.line_color: .clear)
                            .padding(0)
                    }
                    BusStopPoint(stopCase: stopCase, outer_circle_size: stopCase.outer_circle_size, outer_circle_color: stopCase.outer_circle_color)
                        .frame(width: 16, height: 16)
                }
                .overlay(
                    Group {
                        if stopCase.contains(.currentStop) {
                            Image("current_bus")
                                .resizable()
                                .frame(width: 40, height: 36)
                                .offset(x: -47) // Point 왼쪽에 고정
                        }
                    },
                    alignment: .leading
                )
            }
            // 정류장 텍스트 영역
            VStack(alignment:.leading, spacing: 3) {
                HStack {
                    Text(busStop?.stationNm ?? "이름 없음")
                        .font(.pretendard(.medium, size: 16))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 180, alignment: .leading)
                        .foregroundStyle(stopCase.text_color)
                    
                    Spacer()
                    
                    //                    if let icon = stopCase.trailing_icon {
                    //                        Rectangle()
                    //                            .frame(width: 36, height: 28)
                    //                            .cornerRadius(13)
                    //                            .foregroundStyle(Color.gray900)
                    //                            .overlay(
                    //                                icon
                    //                                    .resizable()
                    //                                    .frame(width: 16, height: 16)
                    //                                    .foregroundColor(stopCase.text_color)
                    //                            )
                    //                            .padding(.trailing, 15)
                    //                    }
                }
                
                Text(busStop?.busRouteNm ?? "노선번호 없음")
                    .font(.pretendard(.medium, size: 12))
                    .foregroundStyle(.gray500)
            }
            .padding(EdgeInsets(top: 20, leading: 35, bottom: 20, trailing: 0))
            Spacer()
            if let icon = stopCase.move_icon {
                Image("code")
                    .padding(.trailing, 20)
            } else {
                Spacer()
                    .frame(width: 40, height: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 78, alignment: .leading)
        .padding(.leading, 60)
        .background(stopCase.background_color)
        .ignoresSafeArea()
    }
}

/// 버스 정류장 옆 노선 라인
struct BusStopLine: View {
    var line_color: Color
    
    var body: some View {
        Rectangle()
            .frame(width: 6, height: 39)
            .foregroundStyle(line_color)
    }
}

/// 버스 정류장 옆 원형 포인트
struct BusStopPoint: View {
    let stopCase: BusStopElementCase
    var inner_circle_size: CGFloat = 10 // 작은 원 사이즈
    var outer_circle_size: CGFloat // 큰 원 사이즈
    var outer_circle_color: Color // 큰 원 색상
    
    var body: some View {
        // currentStop인 경우
//        if stopCase.is_shadow != false {
//            Ellipse()
//                .frame(width: 40, height: 40)
//                .foregroundStyle(.mainpurple.opacity(0.15)) // TODO: opicity 수정 필요
//        }
        Ellipse()
            .frame(width: outer_circle_size, height: outer_circle_size)
            .foregroundStyle(outer_circle_color)
            .overlay(
                Group {
                    if let icon = stopCase.leading_icon {
                        icon
                            .resizable()
                            .frame(width: 24, height: 24)
                    } else {
                        Ellipse()
                            .frame(width: inner_circle_size, height: inner_circle_size)
                            .foregroundStyle(.gray900)
                    }
                }
            )
    }
}


#Preview {
    BusStopElement(stopCase: [.currentStop, .destinationStop])
}
