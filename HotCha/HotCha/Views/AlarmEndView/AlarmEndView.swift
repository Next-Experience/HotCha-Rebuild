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
    
    @EnvironmentObject  var nearestBusViewModel: NearestBusViewModel
    @EnvironmentObject var modalStateViewModel: AlarmModalViewModel
    @AppStorage("remainingStops") var remainingStops: String = "불러오는 중..."
    
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
                        
                        Text(remainingStops)
                            .font(.pretendard(.semibold, size: 16))
                            .foregroundStyle(Color("mainpurple"))
                        
//                        Text((busStopSeoulViewModel.distanceToDestinationStop() ?? 0) >= 0 ? "정거장 전" : "정거장 후")
//                            .font(.pretendard(.semibold, size: 16))
//                            .foregroundStyle(Color("gray300"))
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
                        
                        // 이용기록 저장
                        let currentTime = Date()
                        
                        if let currentBusIndex = busStopSeoulViewModel.getDestinationStationIndex() {
                            let newUsage = Usage_history(
                                route_id: busStopSeoulViewModel.bus?.busRouteId ?? "아이디 없음",
                                city_code: "1",
                                destination_stop_id: String(busStopSeoulViewModel.busStations[currentBusIndex].stationNo),
                                destination_stop_name: busStopSeoulViewModel.busStations[currentBusIndex].stationNm,
                                bus_no: busStopSeoulViewModel.bus?.busRouteNm ?? "번호 없음",
                                route_type: busStopSeoulViewModel.bus?.routeType ?? "타입 없음",
                                get_off_timestamp: currentTime,
                                operator_name: busStopSeoulViewModel.bus?.corpNm ?? "정보 없음",
                                operator_no: "정보 없음", // TODO: 운수사 전번 넣기
                                vehicle_no: "정보 없음" //TODO: vehicle_no 차량번호 넣기
                            )
                            print("newUsage: \(newUsage)")
                            modelContext.insert(newUsage)
                        }
                        
                        // 데이터 초기화
                        busStopSeoulViewModel.leaveAlarm()
                        
                        // 초기 알람 설정 상태로 초기화
                        modalStateViewModel.modalState = .alarmWait
                        modalStateViewModel.bus = nil
                        
                        // 현재버스 위치 찾기 종료
                        nearestBusViewModel.stop()
                        dismiss()
                        
                        
                        
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
