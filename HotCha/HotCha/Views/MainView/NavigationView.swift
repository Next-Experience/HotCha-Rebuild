//
//  SegmentedNavigation.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI

struct NavigationView: View {
    @State var selectedTab = 0

    
    var body: some View {
               VStack {
                   HStack {
                       // 위치 정보
                       MyLocationView()
                       Spacer()
                       
                       
                       // 홈 버튼
                       Text("홈")
                           .padding(.horizontal,10)
                           .font(selectedTab == 0 ? .pretendard(.bold, size: 24) : .pretendard(.regular, size: 24))
                           .foregroundColor(selectedTab == 0 ? Color("mainpurple") : Color("gray600"))
                           .onTapGesture {
                               withAnimation {
                                   selectedTab = 0
                               }
                           }
                       
                       // 이용기록 버튼
                       Text("이용 기록")
                           .padding(.horizontal,10)
                           .font(selectedTab == 1 ? .pretendard(.bold, size: 24) : .pretendard(.regular, size: 24))
                           .foregroundColor(selectedTab == 1 ? Color("mainpurple") : Color("gray600"))
                           .onTapGesture {
                               withAnimation {
                                   selectedTab = 1
                               }
                           }
                       
                       // 설정 버튼
                       Text("설정")
                           .padding(.horizontal,10)
                           .padding(.trailing, 10)
                           .font(selectedTab == 2 ? .pretendard(.bold, size: 24) : .pretendard(.regular, size: 24))
                           .foregroundColor(selectedTab == 2 ? Color("mainpurple") : Color("gray600"))
                           .onTapGesture {
                               withAnimation {
                                   selectedTab = 2
                               }
                           }
                   }
                   .frame(height: 62)
                   .padding(.top, 54)
                   

                   // 아래쪽 탭뷰
                   TabView(selection: $selectedTab) {
                       MainView()
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
               }.background(Color("gray900")) // 전채 배경색
            // 아래쪽 여백 제거
            .ignoresSafeArea(.all)       
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
