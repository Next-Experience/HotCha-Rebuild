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
    @State private var isTapped: Bool = false
    @Environment(\.modelContext) private var modelContext
    
   private func deleteBookmark(_ bookmark: Bookmarkmodel) {
       modelContext.delete(bookmark)
       do {
           try modelContext.save()
       } catch {
           print("즐겨찾기 삭제 실패: \(error)")
       }
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
}
