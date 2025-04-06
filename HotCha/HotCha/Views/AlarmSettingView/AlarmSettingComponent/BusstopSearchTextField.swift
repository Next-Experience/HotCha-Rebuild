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
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    
    var body: some View {
        
        VStack {
            HStack{
                HStack{
                    TextField("", text: $busStopSearchText, prompt: Text("도착 정류장을 알려주세요").foregroundColor(.gray300))
                        .font(.pretendard(.medium, size: 16))
                        .foregroundStyle(.gray900)
                        .accentColor(.gray900)
                        .onChange(of: busStopSearchText) {
                            // 약간의 지연을 주어 데이터가 준비되었는지 확인
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if !busStopSearchText.isEmpty {
                                    modalStateViewModel.modalState = .alarmSearch
                                    // 현재 정류장 목록 확인 로그
                                    print("필터링 전 정류장 수: \(busStopSeoulViewModel.busStations.count)")
                                    // 필터링 적용
                                    busStopSeoulViewModel.applyFiltering(with: busStopSearchText)
                                } else {
                                    modalStateViewModel.modalState = .alarmWait
                                    busStopSeoulViewModel.clearFiltering()
                                }
                            }
                        }
                    Spacer()
                    if !busStopSearchText.isEmpty {
                        Button(action: {
                            busStopSearchText = ""
                            // 지우기 버튼 누를 때 하이라이트 제거
                            busStopSeoulViewModel.clearFiltering()
                        }) {
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
        // ViewModel의 검색어가 변경되면 로컬 상태도 업데이트
        .onReceive(busStopSeoulViewModel.$searchText) { viewModelText in
            if viewModelText != busStopSearchText {
                busStopSearchText = viewModelText
            }
        }
        
    }
}
