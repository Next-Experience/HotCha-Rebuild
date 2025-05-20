//
//  testjibangbusstop.swift
//  HotCha
//
//  Created by 문재윤 on 5/20/25.
//

import SwiftUI
import Foundation


class BusStopXMLParser: NSObject, XMLParserDelegate {
    private var busStops: [BusStop] = []
    private var currentElement = ""
    private var currentItem: [String: String] = [:]
    private var completionHandler: (([BusStop]) -> Void)?

    func parse(data: Data, completion: @escaping ([BusStop]) -> Void) {
        self.completionHandler = completion
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentItem = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentItem[currentElement, default: ""] += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if let station = currentItem["nodeid"],
               let stationNm = currentItem["nodenm"],
               let gpsXStr = currentItem["gpslong"],
               let gpsYStr = currentItem["gpslati"],
               let gpsX = Double(gpsXStr),
               let gpsY = Double(gpsYStr),
               let stationNoStr = currentItem["nodeno"],
               let stationNo = Int(stationNoStr),
               let seqStr = currentItem["nodeord"],
               let seq = Int(seqStr),
               let busRouteId = currentItem["routeid"] {
                
                let busStop = BusStop(
                    busRouteId: busRouteId,
                    busRouteNm: "알 수 없음",
                    seq: seq,
                    station: station,
                    stationNm: stationNm,
                    gpsX: gpsX,
                    gpsY: gpsY,
                    stationNo: stationNo
                )
                busStops.append(busStop)
            }
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(busStops)
    }
}
func fetchBusStation(cityCode: String, routeId: String, completion: @escaping ([BusStop], String?) -> Void) {
    let serviceKey = "B%2FSwHGsQuvan%2F%2Fs6M6QvZooclQm9QpSHe%2BqbWjT4xPwDgHNXOES93T9i1%2BDKEJPWfCgcTf12X64bS9A42fFRkA%3D%3D"
    
    let urlString = "http://apis.data.go.kr/1613000/BusRouteInfoInqireService/getRouteAcctoThrghSttnList?serviceKey=\(serviceKey)&pageNo=1&numOfRows=100&_type=xml&cityCode=\(cityCode)&routeId=\(routeId)"
    
    guard let url = URL(string: urlString) else {
        print("❌ URL 생성 실패")
        completion([], "URL 생성 실패")
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            print("❌ 데이터 요청 실패: \(error.localizedDescription)")
            completion([], error.localizedDescription)
            return
        }
        
        guard let data = data else {
            print("❌ 데이터 없음")
            completion([], "데이터 없음")
            return
        }

        let parser = BusStopXMLParser()
        parser.parse(data: data) { busStops in
            completion(busStops, nil) // 에러 없을 경우 nil 전달
        }
    }

    task.resume()
}


import SwiftUI

struct BusStopList___View: View {
    @State private var busStops: [BusStop] = []
    @State private var isLoading: Bool = false
    @State private var isLoaded: Bool = false

    @State private var cityCode: String = "25"
    @State private var routeId: String = "DJB30300004"

    var body: some View {
        VStack {
            Button(action: {
                isLoading = true
                isLoaded = false
                fetchBusStation(cityCode: cityCode, routeId: routeId) { stops,arg  in
                    DispatchQueue.main.async {
                        self.busStops = stops
                        self.isLoading = false
                        self.isLoaded = true
                    }
                }
            }) {
                Text("🚍 정류장 불러오기")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            if isLoading {
                ProgressView("불러오는 중...")
                    .padding()
            }

            if isLoaded {
                if busStops.isEmpty {
                    Text("정류장을 찾을 수 없습니다.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(busStops, id: \.id) { stop in
                        VStack(alignment: .leading) {
                            Text("\(stop.seq). \(stop.stationNm)")
                                .font(.headline)
                            Text("위도: \(stop.gpsY), 경도: \(stop.gpsX)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("버스 정류장 조회")
    }
}
