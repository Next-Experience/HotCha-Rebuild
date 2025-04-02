//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 3/29/25.
//

import SwiftUI
import Foundation

struct BusRoute: Identifiable {
    let id = UUID()
    let busRouteAbrv: String
    let busRouteId: String
    let busRouteNm: String
    let corpNm: String
    let stStationNm: String
    let edStationNm: String
    let firstBusTm: String
    let firstLowTm: String
    let lastBusTm: String
    let lastBusYn: String
    let lastLowTm: String
    let length: String
    let routeType: String
    let term: String
}

class BusRouteViewModel: NSObject, ObservableObject, XMLParserDelegate {
    @Published var busRoutes: [BusRoute] = []
    private var currentElement = ""
    private var currentData: [String: String] = [:]
    private var tempRoutes: [BusRoute] = []
    
    func fetchBusRoutes(searchStr: String) {
        let urlString = "http://ws.bus.go.kr/api/rest/busRouteInfo/getBusRouteList?serviceKey=B%2FSwHGsQuvan%2F%2Fs6M6QvZooclQm9QpSHe%2BqbWjT4xPwDgHNXOES93T9i1%2BDKEJPWfCgcTf12X64bS9A42fFRkA%3D%3D&strSrch=\(searchStr)"
        guard let url = URL(string: urlString) else { return }
        print(urlString)
        tempRoutes = []
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }.resume()
    }
    
    // MARK: - XMLParserDelegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "itemList" {
            currentData = [:]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentData[currentElement, default: ""] += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "itemList" {
            let route = BusRoute(
                busRouteAbrv: currentData["busRouteAbrv"] ?? "N/A",
                busRouteId: currentData["busRouteId"] ?? "N/A",
                busRouteNm: currentData["busRouteNm"] ?? "N/A",
                corpNm: currentData["corpNm"] ?? "N/A",
                stStationNm: currentData["stStationNm"] ?? "N/A",
                edStationNm: currentData["edStationNm"] ?? "N/A",
                firstBusTm: currentData["firstBusTm"] ?? "N/A",
                firstLowTm: currentData["firstLowTm"] ?? "N/A",
                lastBusTm: currentData["lastBusTm"] ?? "N/A",
                lastBusYn: currentData["lastBusYn"] ?? "N/A",
                lastLowTm: currentData["lastLowTm"] ?? "N/A",
                length: currentData["length"] ?? "N/A",
                routeType: currentData["routeType"] ?? "N/A",
                term: currentData["term"] ?? "N/A"
            )
            tempRoutes.append(route)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            self.busRoutes = self.tempRoutes
        }
    }
}


import SwiftData

func saveBusRoutesToDatabase(routes: [BusRoute], context: ModelContext) {
    do {
            let existingRoutes = try context.fetch(FetchDescriptor<Bus_info_seoul>())
            for route in existingRoutes {
                context.delete(route)
            }
            print("🗑️ 기존 데이터를 삭제했습니다.")
        } catch {
            print("❌ 기존 데이터 삭제 실패: \(error)")
        }
    
    for route in routes {
        let newBusInfo = Bus_info_seoul(
            busRouteAbrv: route.busRouteAbrv,
            busRouteId: route.busRouteId,
            busRouteNm: route.busRouteNm,
            corpNm: route.corpNm,
            stStationNm: route.stStationNm,
            edStationNm: route.edStationNm,
            firstBusTm: route.firstBusTm,
            firstLowTm: route.firstLowTm,
            lastBusTm: route.lastBusTm,
            lastBusYn: route.lastBusYn,
            lastLowTm: route.lastLowTm,
            length: route.length,
            routeType: route.routeType,
//            (1:공항, 2:마을, 3:간선, 4:지선, 5:순환, 6:광역, 7:인천, 8:경기, 9:폐지, 0:공용)
            term: route.term
        )

        context.insert(newBusInfo) // SwiftData에 추가
    }
    
    do {
        try context.save() // 변경 사항 저장
        print("✅ 버스 노선 정보가 SwiftData에 저장되었습니다.")
    } catch {
        print("❌ 데이터 저장 실패: \(error)")
    }
}





struct SeoulBusInfoTestView: View {
    @StateObject private var viewModel = BusRouteViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query var bus_info_seoul: [Bus_info_seoul]
    
    var body: some View {
        VStack {
            List(viewModel.busRoutes) { route in
                VStack(alignment: .leading) {
                    Text("\(route.busRouteNm) - \(route.corpNm)").font(.headline)
                   
                }
                
                
            }
            List(bus_info_seoul) { route in
                VStack(alignment: .leading) {
                    Text("\(route.busRouteNm) - \(route.corpNm)zxzz").font(.headline)
                   
                }
        }
                
            Button(action: {
                viewModel.fetchBusRoutes(searchStr: "3")
            }) {
                Text("새로고침")
            }
            .navigationTitle("버스 노선 정보")
            .onAppear {
                viewModel.fetchBusRoutes(searchStr: "")
            }
            


            Button(action: {
                viewModel.fetchBusRoutes(searchStr: "3")
                saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
            }) {
                Text("데이터 저장")
            }
        }
        
        
    }
}

#Preview {
    SeoulBusInfoTestView()
}
