//
//  BookmarkcardView.swift
//  HotCha
//
//  Created by 문재윤 on 2/5/25.
//

import SwiftUI

struct BookmarkCardEmptyView: View {
    let name: String
    let image: String
    var alarmActive: Bool = false
    
    @State private var isTapped: Bool = false
    @State private var showingAddBookmark = false
    @State private var showingAlert = false
    
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                HStack {
                    Image(image)
                    Text(name)
                        .font(.pretendard(.bold, size: 14))
                        .foregroundStyle(Color("gray900"))
                    Spacer()
                    
                    Image("plusicon")
                }
                
                VStack {
                    HStack{
                        Text("장소와 알림을 등록해")
                        Spacer()
                    }
                    HStack{
                        Text("간편하게 이용해 보세요")
                        Spacer()
                    }
                }
                .foregroundStyle(Color("gray300"))
                .font(.pretendard(.medium, size: 14))
                .frame(height: 42)
            }
            .padding(12)
        }
        .background(isTapped ? Color("gray300") : Color("gray150"))
        .cornerRadius(8)
        .onTapGesture {
            if alarmActive {
                showingAlert = true
            } else {
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
            AddBookmarkView(type_name: name)
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



struct BookmarkcardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
