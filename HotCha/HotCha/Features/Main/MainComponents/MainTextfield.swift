//
//  MainTextfiled.swift
//  HotCha
//
//  Created by 문재윤 on 2/5/25.
//

import SwiftUI

struct MainTextfiled: View {
    
    @State private var isTapped: Bool = false
    @FocusState var isTextFieldFocused: Bool
    @Binding var isEditMode: Bool
    
    @Binding var textfiledValue: String
    
    @Binding var searchActivate: Bool
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    var body: some View {
        
        VStack {
            HStack{
                if isBookmark {
                    Text("즐겨찾기 저장")
                        .font(.pretendard(.bold, size: 24))
                        .foregroundStyle(Color("gray900"))
                } else {
                    Text("어디서 알려드릴까요?")
                        .font(.pretendard(.bold, size: 24))
                        .foregroundStyle(Color("gray900"))
                }
                Spacer()
            }
            
            if !searchActivate {
                HStack{
                    HStack{
                        //                    TextField(isBookmark ? "즐겨찾기로 저장할 버스번호를 알려주세요" : "버스 번호, 정류장, 장소", text: $textfiledValue)
                        if !isBookmark {
                            Text("버스 번호나 내릴 정류장을 검색하세요")
                                .font(.pretendard(.medium, size: 16))
                                .foregroundStyle(Color("gray300"))
                        } else {
                            Text("즐겨찾기로 저장할 버스번호를 알려주세요")
                                .font(.pretendard(.medium, size: 16))
                                .foregroundStyle(Color("gray300"))
                        }
                            
                        Spacer()
                        Image("searchbtn")
                    }
                    .padding(16)
                }
                .frame(height: 52)
                .background(isTapped ? Color("gray200") : Color("gray150"))
                .cornerRadius(8)
                .onTapGesture {
                    searchActivate = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isTapped = true
                        isEditMode = false
                        searchActivate = true
                        isBookmark = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                isTapped = false
                            }
                        }
                    }
                }
            } else {
                
                HStack(spacing: 12) {
                    HStack{
                        HStack{
                            TextField(isBookmark ? "즐겨찾기로 저장할 버스번호를 알려주세요" : "버스 번호, 정류장, 장소", text: $textfiledValue)
                                .font(.pretendard(.medium, size: 16))
                                .foregroundStyle(Color("gray300"))
                                .focused($isTextFieldFocused)
                            Spacer()
                            
                        }
                        .padding(16)
                        
                    }
                    .frame(height: 52)
                    .background(isTapped ? Color("gray200") : Color("gray150"))
                    .cornerRadius(8)
                    
                    Text("취소")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("mainpurple"))
                        .onTapGesture {
                                isTapped = true
                                searchActivate = false
                                isTextFieldFocused = false
                                isBookmark = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    isTapped = false
                                }
                            }
                        }
                    
                }
                .onAppear{
                    isTextFieldFocused = true
                }
            }
            
            
        }
        
    }
}
