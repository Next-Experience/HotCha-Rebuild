//
//  Bookmarkcardcustom.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//


import SwiftUI

struct BookmarkCardCustomView: View {
    let isEditMode: Bool
    var bookmark: Bookmarkmodel
    var alarmActive: Bool
    @State private var isTapped: Bool = false
    @State private var showingAlert = false
    @Environment(\.modelContext) private var modelContext
    
    private func deleteBookmark(_ bookmark: Bookmarkmodel) {
        modelContext.delete(bookmark)
        do {
            try modelContext.save()
        } catch {
            print("즐겨찾기 삭제 실패: \(error)")
        }
    }
    
    private func resetCurrentAlarm() {
        // 기존 알람 취소
        UserDefaults.standard.set(false, forKey: "alarmActive")
        UserDefaults.standard.synchronize()
        
        // 알람 상태 변경 알림 발송
        NotificationCenter.default.post(
            name: Notification.Name("AlarmStatusChanged"),
            object: nil,
            userInfo: ["alarmActive": false]
        )
    }
    
    private func startNewAlarmWithBookmark(_ bookmark: Bookmarkmodel) {
        // 북마크 정보를 사용하여 알람 설정
        UserDefaults.standard.set(bookmark.bus_no, forKey: "alarmBusNo")
        UserDefaults.standard.set(bookmark.route_type, forKey: "alarmBusType")
        UserDefaults.standard.set(bookmark.destination_stop_name, forKey: "alarmDestination")
        UserDefaults.standard.set(5, forKey: "alarmRemainingStops") // 기본값으로 5 설정
        UserDefaults.standard.set(bookmark.route_id, forKey: "alarmBusRouteId")
        UserDefaults.standard.set(bookmark.city_code, forKey: "alarmCityCode")
        
        // 알람 활성화
        UserDefaults.standard.set(true, forKey: "alarmActive")
        UserDefaults.standard.synchronize()
        
        // 알람 상태 변경 알림 발송
        NotificationCenter.default.post(
            name: Notification.Name("AlarmStatusChanged"),
            object: nil,
            userInfo: ["alarmActive": true]
        )
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 14 ) {
                HStack {
                    
                    if bookmark.bookmark_type ==  1 {
                        Image("houseicon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    else if bookmark.bookmark_type ==  2 {
                        Image("buildingicon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    else {
                        Image("staricon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    Spacer()
                    
                    Image(isEditMode ? "deleteicon" :"chevron-righticon")
                        .onTapGesture {
                            withAnimation {
                                if isEditMode == true {
                                    deleteBookmark(bookmark)
                                }
                            }
                        }
                    
                }
                
                VStack(spacing: 6) {
                    HStack {
                        BookmarkBusNoView(busNo: bookmark.bus_no, route_type: bookmark.route_type)
                        Spacer()
                    }
                    HStack {
                        Text(bookmark.destination_stop_name)
                            .font(.pretendard(.semibold, size: 16))
                        Spacer()
                    }
                }
                .frame(height: 42)
                
                
            }
            .padding(12)
        }
        .background(isTapped ? Color("gray300") : Color("gray150"))
        .cornerRadius(8)
        .onTapGesture {
            if isEditMode == false {
                if alarmActive {
                    showingAlert = true
                } else {
                    withAnimation {
                        isTapped = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            isTapped = false
                        }
                    }
                }
            }
        }
        .alert("새로운 알림을 시작하시겠어요?", isPresented: $showingAlert) {
            Button("그만두기", role: .cancel) {
                // 취소 동작
            }
            Button("실행하기") {
                // 기존 알림 취소 후 새 알림 설정
                resetCurrentAlarm()
                startNewAlarmWithBookmark(bookmark)
            }
        } message: {
            Text("알림은 한 개만 설정할 수 있어요. 새로운 알림을 시작하면 기존의 설정한 알림이 취소돼요.")
        }
    }
}
