//
//  BookmarkplusView.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import SwiftUI


struct BookmarkPlusView: View {
    @State private var isTapped: Bool = false
    @State private var showingAddBookmark = false

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
            AddBookmarkView(type_name: "")
        }

    }
}
