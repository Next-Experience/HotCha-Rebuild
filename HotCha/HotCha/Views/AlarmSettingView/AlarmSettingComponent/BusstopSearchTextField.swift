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
    @FocusState private var textFieldFocused: Bool
    @Binding var isBookmark: Bool
    
    
    var body: some View {
        
        VStack {
            HStack{
                HStack{
                    TextField("", text: $busStopSearchText, prompt: busStopSeoulViewModel.currentDestinationIndex == nil ?
                              Text("도착 정류장을 알려주세요")
                        .foregroundColor(.gray300)
                              : Text(busStopSeoulViewModel.busStations[busStopSeoulViewModel.currentDestinationIndex!].stationNm
                                    ).foregroundColor(.gray300)
                    )
                    .font(.pretendard(.medium, size: 16))
                    .foregroundStyle(.gray900)
                    .accentColor(.gray900)
                    .focused($textFieldFocused)
                    .onChange(of: textFieldFocused) { newValue in
                        
                        // textField가 포커스되면 alarmSearch로 상태 변경
                        if newValue == true {
                            busStopSeoulViewModel.searchTextFieldfocused = true
                            modalStateViewModel.modalState = .alarmSearch
                            print("TextField가 클릭되었습니다")
                        }
                    }
                    .onChange(of: busStopSeoulViewModel.searchTextFieldfocused) { newValue in
                        // ViewModel에서 포커스 상태가 변경될 때 TextField 업데이트 (정류장 선택 버튼이 눌리면 해당 searchTextFieldfocused의 상태가 변경되고, focus를 해제함)
                        if textFieldFocused != newValue, newValue == false {
                            textFieldFocused = newValue
                        }
                    }
                    
                    .onChange(of: busStopSearchText) {
                        // 약간의 지연을 주어 데이터가 준비되었는지 확인
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !busStopSearchText.isEmpty {
                                // 현재 정류장 목록 확인 로그
                                print("필터링 전 정류장 수: \(busStopSeoulViewModel.busStations.count)")
                                // 필터링 적용
                                busStopSeoulViewModel.applyFiltering(with: busStopSearchText)
                            } else {
                                busStopSeoulViewModel.clearFiltering()
                            }
                        }
                    }
                    Spacer()
                    if !busStopSearchText.isEmpty {
                        Button(action: {
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
            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))
        }
        // ViewModel의 검색어가 변경되면 로컬 상태도 업데이트
        .onReceive(busStopSeoulViewModel.$searchText) { viewModelText in
            if viewModelText != busStopSearchText {
                busStopSearchText = viewModelText
            }
        }
        
    }
}

import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = 0.0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
