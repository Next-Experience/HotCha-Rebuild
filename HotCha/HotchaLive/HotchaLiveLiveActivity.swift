//
//  HotchaLiveLiveActivity.swift
//  HotchaLive
//
//  Created by 문재윤 on 5/6/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HotchaLiveAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
            var progress: Double       // 진행 상태 (0.0 ~ 1.0)
            var currentStop: String    // 현재 정류장
            var stopsRemaining: Int    // 남은 정류장 수
            var alarmstop: String       // 알람 정류장
            var destinationStation: String // 도착 정류장
            var Updatetime: String // 업데이트 시간
        }

        var title: String         // 라이브 액티비티 제목
        var description: String   // 설명
        var busname: String         // 버스 이름
    }


struct HotchaLiveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HotchaLiveAttributes.self) { context in
            // Lock screen/banner UI 만 사용
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        // 버스 번호 및 정류장 정보
                        HStack {
                            Text("\(context.attributes.busname)")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.skybluec)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.skybluec.opacity(0.2))
                                .cornerRadius(4)
                            
                            Text("\(context.state.destinationStation)")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.gray800)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Image("WidgetAppIcon")
                                .resizable()
                                .frame(width: 20, height: 20)
                            
                            Text("핫챠")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.gray400)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    HStack {
                        Text("\(context.state.stopsRemaining)")
                            .font(.pretendard(.semibold, size: 20))
                            .foregroundStyle(.purplec)
                            .padding(.trailing, 4)
                        
                        Text("정류장 전")
                            .font(.pretendard(.semibold, size: 20))
                            .foregroundStyle(.gray700)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom)
                }
                .background(.white)
                
                VStack(spacing: 0) {
                    // 정류장 및 방향 정보
                    HStack {
                        Text("\(context.state.currentStop)")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(.gray800)
                        
                        Image(systemName: "chevron.right")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(.gray800)
                            .padding(.horizontal, 4)
                        
                        Text("\(context.state.alarmstop)")
                            .font(.pretendard(.medium, size: 12))
                            .foregroundColor(.gray600)
                        
                        Spacer()
                        Text("\(context.state.Updatetime)")
                            
                    }
                    .padding(20)
                }
                .background(.gray150)
            }
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
    
    
    private func getBusColor(for routeType: String) -> Color {
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
}




