//
//  AlarmEndView.swift
//  HotCha
//
//  Created by 문재윤 on 3/9/25.
//

import SwiftUI

struct AlarmEndView: View {
    
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                HStack{
                    Text("목적지로부터")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("gray300"))
                    Text("00")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("mainpurple"))
                    Text("정거장 전")
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("gray300"))
                }
                .padding(.bottom, 12)
                
                Text("해운대도시철도역")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("gray50"))
                    .padding(.bottom, 30)
                
                HStack {
                    Text("확인")
                        .font(.pretendard(.semibold, size: 18))
                        .padding(13)
                        .foregroundStyle(Color("gray900"))
                }
                .frame(width: 150)
                .background(Capsule().fill(Color("mainpurple")))
                
                
            }
            .frame(width: 320, height: 320)
            .background(Circle().fill(Color("mainpurple").opacity(0.3)))
            
            VStack {
            
            Spacer()
            
                HStack {
                    Text("안내 종료")
                        .font(.pretendard(.semibold, size: 18))
                        .padding(13)
                        .foregroundStyle(Color("gray300"))
                }
                
                .frame(width: 150)
                .background(Capsule().fill(Color("gray400").opacity(0.4)))
            }
            .padding(.bottom, 37)
          
            
            
            
            
        }
        .frame(width: 520, height: 520)
        .background(Circle().fill(Color("mainpurple").opacity(0.3)))
    }
}

#Preview {
    AlarmEndView()
}
