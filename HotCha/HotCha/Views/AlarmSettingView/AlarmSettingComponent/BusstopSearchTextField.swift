//
//  BusstopSearchTextField.swift
//  HotCha
//
//  Created by Yeji Seo on 2/25/25.
//

import SwiftUI

enum FocusableField: Hashable {
        case busStopName
        case roomNo
    }

struct BusStopSearchTextField: View {
    @Binding var busStopSearchText: String
    @FocusState var focusField: FocusableField?
    
    var body: some View {
        
        VStack {
            HStack{
                HStack{
                    TextField("", text: $busStopSearchText, prompt: Text("도착 정류장을 알려주세요").foregroundColor(.gray300))
                        .font(.pretendard(.medium, size: 16))
                        .focused($focusField, equals: .busStopName)
                        .foregroundStyle(.gray900)
                        .accentColor(.gray900)
                    Spacer()
                    if !busStopSearchText.isEmpty {
                        Button(action: { busStopSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray300)
                        }
                    }
                    else {
                        Image("searchbtn")
                    }
                }
                .padding(16)
            }
            .frame(height: 52)
            .background(.gray150)
            .cornerRadius(8)
        }
    }
}

#Preview {
//    BusStopSearchTextField(busStopSearchText:  .constant("asd"))
    ContentView()
}


import SwiftUI

struct ContentView: View {
    @State private var showingSheet = false
    @State private var selectedItem1: String?
    @State private var selectedItem2: String?
    
    var body: some View {
        VStack {
            Button("검색하기") {
                showingSheet = true
            }
            
            if let item1 = selectedItem1 {
                Text("첫 번째 선택: \(item1)")
            }
            
            if let item2 = selectedItem2 {
                Text("두 번째 선택: \(item2)")
            }
            
            List {
                // 메인 화면의 리스트 내용
                Text("메인 리스트 항목 1")
                Text("메인 리스트 항목 2")
                // ...
            }
        }
        .sheet(isPresented: $showingSheet) {
            SearchSheetView(selectedItem1: $selectedItem1, selectedItem2: $selectedItem2)
        }
    }
}

struct SearchSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedItem1: String?
    @Binding var selectedItem2: String?
    
    @State private var searchText1 = ""
    @State private var searchText2 = ""
    
    // 샘플 데이터
    let allItems1 = ["사과", "바나나", "오렌지", "포도", "딸기"]
    let allItems2 = ["서울", "부산", "인천", "대구", "광주"]
    
    var filteredItems1: [String] {
        if searchText1.isEmpty {
            return allItems1
        } else {
            return allItems1.filter { $0.contains(searchText1) }
        }
    }
    
    var filteredItems2: [String] {
        if searchText2.isEmpty {
            return allItems2
        } else {
            return allItems2.filter { $0.contains(searchText2) }
        }
    }
    
    var body: some View {
        VStack {
            // 첫 번째 검색창
            TextField("첫 번째 항목 검색", text: $searchText1)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // 첫 번째 검색 결과 리스트
            List {
                ForEach(filteredItems1, id: \.self) { item in
                    Text(item)
                        .onTapGesture {
                            selectedItem1 = item
                        }
                }
            }
            .frame(height: 200) // 리스트 높이 제한
            
            // 두 번째 검색창
            TextField("두 번째 항목 검색", text: $searchText2)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // 두 번째 검색 결과 리스트
            List {
                ForEach(filteredItems2, id: \.self) { item in
                    Text(item)
                        .onTapGesture {
                            selectedItem2 = item
                        }
                }
            }
            
            Button("완료") {
                dismiss()
            }
            .padding()
        }
        .padding(.top)
    }
}
