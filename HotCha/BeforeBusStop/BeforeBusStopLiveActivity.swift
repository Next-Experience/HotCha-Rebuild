//
//  BeforeBusStopLiveActivity.swift
//  BeforeBusStop
//
//  Created by 문호 on 4/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BeforeBusStopAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 실시간으로 업데이트될 버스 정보
    }
    
    // Fixed non-changing properties about your activity go here!
    var name: String
}

// Live Activity UI 작업할 곳
struct BeforeBusStopLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BeforeBusStopAttributes.self) { context in
            // Lock screen/banner UI 만 사용
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        // 버스 번호 및 정류장 정보
                        HStack {
                            Text("500")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.skybluec)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.skybluec.opacity(0.2))
                                .cornerRadius(4)
                            
                            Text("서울역버스환승센터")
                                .font(.pretendard(.semibold, size: 14))
                                .foregroundStyle(.gray800)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Image("AppIcon")
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
                        Text("5")
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
                        Text("남대문시장앞.이회영활동터")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(.gray800)
                        
                        Image(systemName: "chevron.right")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(.gray800)
                            .padding(.horizontal, 4)
                        
                        Text("장지역환승센터")
                            .font(.pretendard(.medium, size: 12))
                            .foregroundColor(.gray600)
                        
                        Spacer()
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
    
    
    func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


extension BeforeBusStopAttributes {
    fileprivate static var preview: BeforeBusStopAttributes {
        BeforeBusStopAttributes(name: "world")
    }
}

extension BeforeBusStopAttributes.ContentState {
    fileprivate static var smiley: BeforeBusStopAttributes.ContentState {
        BeforeBusStopAttributes.ContentState()
    }
}

#Preview("Notification", as: .content, using: BeforeBusStopAttributes.preview) {
    BeforeBusStopLiveActivity()
} contentStates: {
    BeforeBusStopAttributes.ContentState.smiley
}
