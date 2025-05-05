//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/5/25.
//

import SwiftUI
import SwiftData


struct BookmarkView: View {
    @Binding var bus: Bus_info_seoul // 선택된 버스 정보
    @Binding var cityCode: Int
    @Environment(\.modelContext) private var modelContex
    @Query var bookmarkdata: [Bookmarkmodel]
    @Binding var isEditMode: Bool
    
    var alarmActive: Bool
    @Binding var searchActivate: Bool
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    let columns: [GridItem] = [
            GridItem(.flexible(), spacing: 15),
            GridItem(.flexible(), spacing: 15)
        ]

    var body: some View {
        VStack {
            // 상단 설명과 편집 버튼
            HStack{
                Text("즐겨찾기 알림 (2/6)")
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color("gray900"))
                Spacer()

                
                Text(isEditMode ? "완료" : "편집")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(isEditMode ? Color("mainpurple") : Color("gray600"))
                        .onTapGesture {
                            // 편집 모드 토글
                            isEditMode.toggle()
                        }
            }
            .padding(.bottom, 12)
            VStack(spacing: 16) {
                // 집 회사
                LazyVGrid(columns: columns, spacing: 16) {
                    let homebookmark = bookmarkdata.filter { $0.bookmark_type == 1 }
                    if homebookmark.isEmpty {
                        BookmarkCardEmptyView(name: "집", image: "houseicon", alarmActive: alarmActive, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name)
                        } else {
                            ForEach(homebookmark) { bookmark in
                                BookmarkCardCustomView(isEditMode: isEditMode, bookmark: bookmark, alarmActive: alarmActive)
                            }
                        }
                    
                    let workplacebookmark = bookmarkdata.filter { $0.bookmark_type == 2 }
                    if workplacebookmark.isEmpty {
                        BookmarkCardEmptyView(name: "회사", image: "buildingicon", alarmActive: alarmActive, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name)
                        } else {
                            ForEach(workplacebookmark) { bookmark in
                                BookmarkCardCustomView(isEditMode: isEditMode, bookmark: bookmark, alarmActive: alarmActive)
                            }
                        }
                    }
                
                // 직접 추가하는 즐겨찾기
                let bookmarks = bookmarkdata.filter { $0.bookmark_type == 0 }
                LazyVGrid(columns: columns, spacing: 16) { ForEach(bookmarks) { bookmark in
                    BookmarkCardCustomView(isEditMode: isEditMode, bookmark: bookmark, alarmActive: alarmActive)
                }
                    if bookmarks.count < 4 {
                        if !isEditMode {
                            BookmarkPlusView(alarmActive: alarmActive, searchActivate: $searchActivate, isBookmark: $isBookmark, type_name: $type_name)
                        }
                        }
                }
            }
            

        }
    }
}



struct BookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
