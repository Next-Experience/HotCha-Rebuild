//
//  SearchHistoryView.swift
//  HotCha
//
//  Created by 문재윤 on 2/28/25.
//

import SwiftUI
import SwiftData

struct SearchHistoryView: View {
    @Environment(\.modelContext) private var modelContex
    @Query var Usage_history: [Usage_history]
    
    var body: some View {
        HStack {
            Text("최근 이용 기록")
                .font(.pretendard(.medium, size: 16))
                .foregroundColor(Color("gray300"))
                .padding(.top, 6)
            Spacer()
        }
            ScrollView {
                VStack {
                    ForEach(Usage_history) {history in
                        SerachHistoryBlockView(history: history)
                    }
                }
            }
            
        }

    }


