//
//  OnBoardingView.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct OnBoardingView: View {
    @State var OnBoardingTab = 0
    
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                OnboardingPointview(OnBoardingTab: $OnBoardingTab)
                    .padding(.top, 30)
                    .padding(.horizontal, 30)
                
                    TabView(selection: $OnBoardingTab) {
                        OnBoarding0View()
                            .ignoresSafeArea()
                            .tag(0)
                        OnBoarding1View()
                            .ignoresSafeArea()
                            .tag(1)
                        OnBoarding2View()
                            .ignoresSafeArea()
                            .tag(2)
                        OnBoarding3View()
                            .ignoresSafeArea()
                            .tag(3)
                    }
                    // 인디케이터 숨겼음, 페이지 탭뷰로 스와이프 기능 넣음
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                Spacer()

                OnboardingButtonview()
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        
                    }
                
            }
           
        }
        
        .background(Color("gray900"))
        
    }
}




#Preview {
    OnBoardingView()
}
