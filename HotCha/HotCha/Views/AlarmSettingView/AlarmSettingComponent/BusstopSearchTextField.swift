//
//  BusstopSearchTextField.swift
//  HotCha
//
//  Created by Yeji Seo on 2/25/25.
//

import SwiftUI

struct BusStopSearchTextField: View {
    @Binding var busStopSearchText: String
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel = BusStopSeoulViewModel()
    
    var body: some View {
        
        VStack {
            HStack{
                HStack{
                    TextField("", text: $busStopSearchText, prompt: Text("도착 정류장을 알려주세요").foregroundColor(.gray300))
                        .font(.pretendard(.medium, size: 16))
                        .foregroundStyle(.gray900)
                        .accentColor(.gray900)
                        .onChange(of: busStopSearchText){
                            if !busStopSearchText.isEmpty {
                                modalStateViewModel.modalState = .alarmSearch
                                busStopSeoulViewModel.filteredBusStations(searchText: busStopSearchText)
                            }
                            else {
                                modalStateViewModel.modalState = .alarmWait
                            }
                        }
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
