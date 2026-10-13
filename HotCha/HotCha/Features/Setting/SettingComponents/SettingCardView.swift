//
//  SettingCardView.swift
//  HotCha
//
//  Created by 문재윤 on 2/6/25.
//

import SwiftUI

struct SettingCardView: View {
    let icon: String
    let name: String
    
    @State private var isTapped: Bool = false
    
    var body: some View {
        HStack {
            HStack {
                HStack{
                    Image(icon)
                    Text(name)
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("gray900"))
                }
                Spacer()
                
                Image("chevron-righticon")
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .background(isTapped ? Color("gray300") : Color("gray150"))
        .cornerRadius(8)
        .onTapGesture {
            withAnimation {
                isTapped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isTapped = false
                }
            }
        }
        
    }
}

struct SettingCardView_Previews: PreviewProvider {
    static var previews: some View {
        SettingCardView(icon: "questionmarkicon", name: "미리보기")
    }
}
