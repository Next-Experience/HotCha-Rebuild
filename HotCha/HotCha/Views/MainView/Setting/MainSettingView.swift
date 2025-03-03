//
//  MainSetting.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI

struct MainSettingView: View {
    var body: some View {
        VStack{
            VStack(spacing: 24) {
               VStack(spacing: 12) {
                    HStack {
                        Text("고객지원")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(Color("gray800"))
                        Spacer()
                    }
                    SettingCardView(icon: "mailicon", name: "핫챠 문의하기")
                    SettingCardView(icon: "questionmarkicon", name: "자주 묻는 질문")
                    SettingCardView(icon: "fileicon", name: "이용약관 및 개인정보처리방침")
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text("앱정보")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(Color("gray800"))
                                                Spacer()
                    }
                    
                    SettingCardVersionView(icon: "fileicon", name: "버전 정보", version: getAppVersion() ?? "0.0.0")
                }
                
                Spacer()
            }
            .padding(20)
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("gray50"))
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hideKeyboard()
            }
          
        }
        
    }
}

struct MainSetting_Previews: PreviewProvider {
    static var previews: some View {
        MainSettingView()
    }
}
