//
//  SearchView.swift
//  HotCha
//
//  Created by 문재윤 on 2/24/25.
//
import SwiftUI

struct SearchView: View {
    @Binding var textfiledValue: String
    @Binding var searchActivate: Bool
    
    
    var body: some View {
        if textfiledValue.isEmpty {
            SearchHistoryView()
        } else {
            Text("버스 목록")
        }
    }
}


