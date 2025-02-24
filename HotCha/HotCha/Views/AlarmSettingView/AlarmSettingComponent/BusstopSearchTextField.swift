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

struct BusstopSearchTextField: View {
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
    BusstopSearchTextField(busStopSearchText:  .constant("asd"))
}
