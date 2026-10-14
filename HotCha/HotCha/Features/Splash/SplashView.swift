//
//  SplashView.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isSplashActive = false
    @AppStorage("OnBoarding_True") var OnBoardingTrue: Bool = false
    
    var body: some View {
        if isSplashActive {
            if OnBoardingTrue {
                NavigationView()
            } else {
                OnBoardingView()
            }
            
        } else {
            VStack {
                Spacer()
                HStack {
                    Text("안전하게")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 30)
                HStack {
                    Text("핫챠")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(Color("mainpurple"))
                    Text("하세요")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 30)
                Image("splashbus")
                    .padding(.bottom, 70)
            }
            .background(HotChaContentBackground())
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    isSplashActive = true
                    
                }
            }
        }
        
        
    }
}


#Preview {
    SplashView()
}
