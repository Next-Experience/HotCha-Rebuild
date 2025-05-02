//
//  BookmarkplusView.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import SwiftUI


struct BookmarkPlusView: View {
    var alarmActive: Bool = false // 알람 상태 추가 (기본값으로 false)
    @State private var isTapped: Bool = false
    @State private var showingAddBookmark = false
    @State private var showingAlert = false // 알림 창 표시 여부

    var body: some View {
        VStack {
            HStack{
                Spacer()
                Image("bigplusicon")
                Spacer()
            }
            .padding(34)
        }
        .background(isTapped ? Color("gray300") : Color("gray150"))
        .cornerRadius(8)
        .onTapGesture {
            if alarmActive {
                // 알람이 활성화된 상태에서는 알림 창 표시
                showingAlert = true
            } else {
                // 알람이 비활성화된 상태에서는 기존 동작 유지
                withAnimation {
                    isTapped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isTapped = false
                        showingAddBookmark = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBookmark) {
            AddBookmarkView(type_name: "")
        }
        .alert("새로운 알림을 시작하시겠어요?", isPresented: $showingAlert) {
            Button("그만두기", role: .cancel) {
                // 취소 동작
            }
            Button("실행하기") {
                // 새 알림 설정 전에 먼저 북마크 추가 화면으로 이동
                showingAlert = false
                showingAddBookmark = true
            }
        } message: {
            Text("알림은 한 개만 설정할 수 있어요. 새로운 알림을 시작하면 기존의 설정한 알림이 취소돼요.")
        }
    }
}
