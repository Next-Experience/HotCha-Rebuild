//
//  SegmentedNavigation.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI

struct NavigationView: View {
    @State var selectedTab = 0
    @State private var isTouching = true
    @State var isSwipeDisabled = false
    let lastPageIndex = 2

    
    var body: some View {
        NavigationStack {
                   VStack(spacing: 0) {
                       HStack {
                           // 위치 정보
                           MyLocationView()
                           Spacer()
                           
                           HStack(spacing: 0) {
                               ZStack {
                                   // 홈 버튼
                                   Text("홈")
                                       .padding(.horizontal,10)
                                       .font(selectedTab == 0 ? .pretendard(.bold, size: 24) : .pretendard(.medium, size: 24))
                                       .foregroundColor(selectedTab == 0 ? Color("mainpurple") : Color("gray600"))
                                       .onTapGesture {
                                           withAnimation {
                                               selectedTab = 0
                                           }
                                       }
                                   
                                   VStack(spacing: 0) {
                                       Spacer()
                                       Image("NavigationPoint")
                                           .offset(y: selectedTab == 0 ? 30 : 40)
                                           .opacity(selectedTab == 0 ? 1 : 0)
    //                                       .animation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0.1), value: selectedTab)
                                   }
                                   
                               }
                               
                               ZStack {
                                   // 이용기록 버튼
                                   Text("이용 기록")
                                       .padding(.horizontal,10)
                                       .font(selectedTab == 1 ? .pretendard(.bold, size: 24) : .pretendard(.medium, size: 24))
                                       .foregroundColor(selectedTab == 1 ? Color("mainpurple") : Color("gray600"))
                                       .onTapGesture {
                                           withAnimation {
                                               selectedTab = 1
                                           }
                                       }
                                   
                                   VStack(spacing: 0) {
                                       Spacer()
                                       Image("NavigationPoint")
                                           .offset(y: selectedTab == 1 ? 30 : 40)
                                           .opacity(selectedTab == 1 ? 1 : 0)
    //                                       .animation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0.1), value: selectedTab)
                                   }
                                   
                                   
                               }
                               ZStack {
                                   // 설정 버튼
                                   Text("설정")
                                       .padding(.horizontal,10)
                                       .padding(.trailing, 10)
                                       .font(selectedTab == 2 ? .pretendard(.bold, size: 24) : .pretendard(.medium, size: 24))
                                       .foregroundColor(selectedTab == 2 ? Color("mainpurple") : Color("gray600"))
                                       .onTapGesture {
                                           withAnimation {
                                               selectedTab = 2
                                           }
                                       }
                                   if isTouching {
                                       VStack(spacing: 0) {
                                           Spacer()
                                           Image("NavigationPoint")
                                               .offset(y: selectedTab == 2 ? 30 : 40)
                                               .opacity(selectedTab == 2 ? 1 : 0)
    //                                           .animation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0.1), value: selectedTab)
                                       }
                                   }
                                   
                                   
                               }
                           }
                           .frame(width: .infinity)
                       }
                           .frame(height: 62)
                           .padding(.top, 54)
                       

                       // 아래쪽 탭뷰
                       TabView(selection: Binding(
                        get: { selectedTab },
                        set: { selectedTab = min($0, lastPageIndex) }
                    )) {
                           MainView(isSwipeDisabled : $isSwipeDisabled)
                               .cornerRadius(10)
                               .ignoresSafeArea()
                               .padding(.horizontal, 2)
                               .tag(0)
                           MainUsageHistoryView()
                               .cornerRadius(10)
                               .ignoresSafeArea()
                               .padding(.horizontal, 2)
                               .tag(1)
                           MainSettingView()
                               .cornerRadius(10)
                               .ignoresSafeArea()
                               .padding(.horizontal, 2)
                               .tag(2)
                           }
                       // 인디케이터 숨겼음, 페이지 탭뷰로 스와이프 기능 넣음
                       .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                       .disabled(isSwipeDisabled)
                   }.background(Color("gray900")) // 전채 배경색
                .ignoresSafeArea(.all)   
               }
            // 아래쪽 여백 제거
                
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
