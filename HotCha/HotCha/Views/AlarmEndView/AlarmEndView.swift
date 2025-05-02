//
//  AlarmEndView.swift
//  HotCha
//
//  Created by 문재윤 on 3/9/25.
//

import SwiftUI

struct AlarmEndView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sheetManager: AlarmSettingModalSheetManager
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @EnvironmentObject var busLocationViewModel: BusLocationViewModel
    
    var body: some View {
        
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
                
                Text("\(busStopSeoulViewModel.busStations[busStopSeoulViewModel.getDestinationStationIndex() ?? 0].stationNm)")
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
                .onTapGesture {
                    dismiss()
                    sheetManager.showAlarmInfoSheet2 = true
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
                    dismiss()
                    busLocationViewModel.stopFetching()
                }
            }
            .padding(.bottom, 37)
        }
        .frame(width: 520, height: 520)
        .background(Circle().fill(Color("mainpurple").opacity(0.3)))
        .navigationBarBackButtonHidden(true) // 기본 뒤로가기 버튼 숨기기
    }
        
    
}

#Preview {
    AlarmEndView()
}
