//
//  AlarmEndView.swift
//  HotCha
//
//  Created by 문재윤 on 3/9/25.
//

import SwiftUI

struct AlarmEndView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel

    @ObservedObject private var vm = NearestBusViewModel()
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel

    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            ZStack {
                VStack(spacing: 0) {
                    HStack{
                        Text("목적지로부터")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(Color("gray300"))
                        if let distanceToDestinationStop = busStopSeoulViewModel.distanceToDestinationStop() {
                            Text(String(format: "%02d", abs(distanceToDestinationStop)))
                                .font(.pretendard(.semibold, size: 16))
                                .foregroundStyle(Color("mainpurple"))
                        }
                        
                        Text((busStopSeoulViewModel.distanceToDestinationStop() ?? 0) >= 0 ? "정거장 전" : "정거장 후")
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(Color("gray300"))
                    }
                    .padding(.bottom, 12)
                    
                    if let index = busStopSeoulViewModel.getDestinationStationIndex(),
                       index < busStopSeoulViewModel.busStations.count {
                        Text("\(busStopSeoulViewModel.busStations[index].stationNm)")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundStyle(Color("gray50"))
                            .padding(.bottom, 30)
                    } else {
                        Text("정류장 정보 없음")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundStyle(Color("gray50"))
                            .padding(.bottom, 30)
                    }
//                    Text("\(busStopSeoulViewModel.busStations[busStopSeoulViewModel.getDestinationStationIndex() ?? 0].stationNm)")
                        
                    
                    HStack {
                        Text("확인")
                            .font(.pretendard(.semibold, size: 18))
                            .padding(13)
                            .foregroundStyle(Color("gray900"))
                    }
                    .frame(width: 150)
                    .background(Capsule().fill(Color("mainpurple")))
                    .onTapGesture {
                        startAlarmToggle(
                            isOn: false,
                            title: "",
                            body: "",
                            useSound: false,
                            useVibration: false
                        )
                        
                        busStopSeoulViewModel.navigateToAlarmEndView = false // AlarmEndView 닫기
                        sheetManager.showAlarmInfoSheet2 = true // 시트2 열기
                    }
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
                    .onTapGesture {
                        startAlarmToggle(
                            isOn: false,
                            title: "",
                            body: "",
                            useSound: false,
                            useVibration: false
                        )
                        // 이용기록 및 데이터 초기화
                        busStopSeoulViewModel.leaveAlarm(modelContext: modelContext)
                        // 초기 알람 설정 상태로 초기화
                        modalStateViewModel.modalState = .alarmWait
                        modalStateViewModel.bus = nil

                        dismiss()
                        busLocationViewModel.stopFetching()
                        
                        
                    }
                }
                .padding(.bottom, 37)
            }
            .frame(width: 520, height: 520)
            .background(Circle().fill(Color("mainpurple").opacity(0.3)))
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
        .navigationBarBackButtonHidden(true) // 기본 뒤로가기 버튼 숨기기
        .background(Color.clear.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    AlarmEndView()
}
