//
//  BusListView.swift
//  HotCha
//
//  Created by 문재윤 on 5/20/25.
//


import SwiftUI
import SwiftData

struct BusListView: View {
    @State private var buses: [Bus] = []
    @State private var cityCode: String = "21" // 예: 서울시 코드
    @State private var routeNo: String = ""   // 예: 버스 번호
    @Environment(\.modelContext) private var modelContext // SwiftData 컨텍스트

    var body: some View {
        VStack {
            VStack {
                // 검색 입력창
                HStack {
                    TextField("도시 코드 입력", text: $cityCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    TextField("버스 번호 입력", text: $routeNo)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("검색") {
                        fetchBusData(citycode: 21, routeNo: "" ) { result in
                            buses = result }
                        
                        
                        fetchBusData(citycode: 21, routeNo: "") { result in
                            DispatchQueue.main.async {
                                self.buses = result
                                savejibangBusRoutesToDatabase(buses: result, cityCode: cityCode, context: modelContext)
                            }
                        }
                    }
                }
                .padding()

                List(buses) { bus in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("노선 번호: \(bus.routeno)")
                            .font(.headline)
                        Text("출발: \(bus.startnodenm)")
                        Text("도착: \(bus.endnodenm)")
                        Text("출발 시간: \(bus.startvehicletime)")
                        Text("도착 시간: \(bus.endvehicletime)")
                        Text("노선 타입: \(bus.routetp)")
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("버스 노선 정보")
        }
    }
    
  
       
        
    
}



func savejibangBusRoutesToDatabase(buses: [Bus], cityCode: String, context: ModelContext) {

    for bus in buses {
        let newBusInfo = Bus_info_seoul(
            busRouteAbrv: bus.routeno,
            busRouteId: bus.routeid,
            busRouteNm: bus.routeno,
            corpNm: "",
            stStationNm: bus.startnodenm,
            edStationNm: bus.endnodenm,
            firstBusTm: bus.startvehicletime,
            firstLowTm: "",
            lastBusTm: bus.endvehicletime,
            lastBusYn: "",
            lastLowTm: "",
            length: "",
            routeType: bus.routetp,
            term: "",
            city_code: cityCode // <- 이제 매개변수로 받은 값
        )

        context.insert(newBusInfo)
    }

    do {
        try context.save()
        print("✅ 버스 정보가 SwiftData에 저장되었습니다.")
    } catch {
        print("❌ 저장 중 오류 발생: \(error)")
    }
}
