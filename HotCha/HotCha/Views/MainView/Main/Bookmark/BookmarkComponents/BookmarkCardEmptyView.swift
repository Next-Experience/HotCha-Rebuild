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
    
    @State private var isTapped: Bool = false
    @State private var showingAddBookmark = false


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
        .sheet(isPresented: $showingAddBookmark) {
            AddBookmarkView(type_name: name)
        }

    }
}



struct BookmarkcardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
