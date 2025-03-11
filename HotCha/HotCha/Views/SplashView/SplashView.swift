//
//  SplashView.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isSplashActive = false
    
    var body: some View {
        if isSplashActive {
            NavigationView()
        } else {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("안전하게 핫챠하세요")
                        .font(.pretendard(.bold, size: 24))
                        .foregroundStyle(Color("gray50"))
                        .padding(.bottom, 200)
                    Spacer()
                }
                Spacer()
            }
            .background(Color("gray900"))
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
