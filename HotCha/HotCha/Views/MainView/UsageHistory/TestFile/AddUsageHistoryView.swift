//
//  AddUsageHistoryView.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//


import SwiftUI
import SwiftData

struct AddUsageHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var bus: Bus_info_seoul = Bus_info_seoul(
        busRouteAbrv: "알 수 없음",
        busRouteId: "알 수 없음",
        busRouteNm: "알 수 없음",
        corpNm: "알 수 없음",
        stStationNm: "출발지 미정",
        edStationNm: "도착지 미정",
        firstBusTm: "--:--",
        firstLowTm: "--:--",
        lastBusTm: "--:--",
        lastBusYn: "N",
        lastLowTm: "--:--",
        length: "0",
        routeType: "0",
        term: "0",
        city_code: "1"
    )
    @State private var routeID: String = ""
    @State private var cityCode: String = ""
    @State private var destinationStopID: String = ""
    @State private var busNo: String = ""
    @State private var routeType: String = ""
    @State private var operatorName: String = ""
    @State private var vehicleNo: String = ""
    @State private var getOffTimestamp: Date = Date()
    @State private var operatorno: String = ""
    @State private var destinationStopname: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("사용 내역 입력")) {
                    TextField("노선 ID", text: $routeID)
                    TextField("도시 코드", text: $cityCode)
                    TextField("정류장 ID", text: $destinationStopID)
                    TextField("정류장 name", text: $destinationStopname)
                    TextField("버스 번호", text: $busNo)
                    TextField("노선 타입", text: $routeType)
                    TextField("운행사 이름 (선택)", text: $operatorName)
                    TextField("차량 번호 (선택)", text: $vehicleNo)
                    TextField("전번", text: $operatorno)
                    
                    DatePicker("하차 시간", selection: $getOffTimestamp, displayedComponents: [.date, .hourAndMinute])
                }
                // TODO: 안내 종료할 때 이 버튼을 안내 종료 버튼에 붙여넣기
                Button("저장") {
                    let newUsage = Usage_history(
                        bus: BusFavoriteHistory(from: bus),
                        route_id: routeID,
                        city_code: cityCode,
                        destination_stop_id: destinationStopID, destination_stop_name: destinationStopname,
                        bus_no: busNo,
                        route_type: routeType,
                        get_off_timestamp: getOffTimestamp,
                        operator_name: operatorName.isEmpty ? nil : operatorName,
                        operator_no: operatorno.isEmpty ? nil : operatorno,
                        vehicle_no: vehicleNo
                    )
                    
                    modelContext.insert(newUsage)
                    dismiss()
                }
            }
            .navigationTitle("사용 내역 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}
