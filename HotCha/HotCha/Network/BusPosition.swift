//
//  BusPosition.swift
//  HotCha
//
//  Created by 문재윤 on 4/24/25.
//


import Foundation

// BusPosition 구조체는 기존 BusInfo를 대체합니다.
struct BusPosition: Identifiable {
    var id: String {
        vehId // 각 버스의 ID는 vehId로 식별합니다.
    }
    var busType: String
    var congetion: String
    var dataTm: String
    var fullSectDist: String
    var gpsX: Double
    var gpsY: Double
    var isFullFlag: String
    var islastyn: String
    var isrunyn: String
    var lastStTm: String
    var lastStnId: String
    var nextStId: String
    var nextStTm: String
    var plainNo: String
    var posX: Double
    var posY: Double
    var rtDist: String
    var sectDist: String
    var sectOrd: String
    var sectionId: String
    var stopFlag: String
    var trnstnid: String
    var vehId: String
}

import Foundation

class BusPosXMLParser: NSObject, ObservableObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentBusPosition: [String: String] = [:]
    private var busPositions = [BusPosition]()
    var completionHandler: (([BusPosition]) -> Void)?

    func parse(data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // XMLParserDelegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        currentBusPosition[currentElement] = (currentBusPosition[currentElement] ?? "") + trimmedString
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "itemList" {
            guard let gpsX = Double(currentBusPosition["gpsX"] ?? ""),
                  let gpsY = Double(currentBusPosition["gpsY"] ?? ""),
                  let posX = Double(currentBusPosition["posX"] ?? ""),
                  let posY = Double(currentBusPosition["posY"] ?? "") else {
                currentBusPosition.removeAll()
                return
            }

            let busPosition = BusPosition(
                busType: currentBusPosition["busType"] ?? "",
                congetion: currentBusPosition["congetion"] ?? "",
                dataTm: currentBusPosition["dataTm"] ?? "",
                fullSectDist: currentBusPosition["fullSectDist"] ?? "",
                gpsX: gpsX,
                gpsY: gpsY,
                isFullFlag: currentBusPosition["isFullFlag"] ?? "",
                islastyn: currentBusPosition["islastyn"] ?? "",
                isrunyn: currentBusPosition["isrunyn"] ?? "",
                lastStTm: currentBusPosition["lastStTm"] ?? "",
                lastStnId: currentBusPosition["lastStnId"] ?? "",
                nextStId: currentBusPosition["nextStId"] ?? "",
                nextStTm: currentBusPosition["nextStTm"] ?? "",
                plainNo: currentBusPosition["plainNo"] ?? "",
                posX: posX,
                posY: posY,
                rtDist: currentBusPosition["rtDist"] ?? "",
                sectDist: currentBusPosition["sectDist"] ?? "",
                sectOrd: currentBusPosition["sectOrd"] ?? "",
                sectionId: currentBusPosition["sectionId"] ?? "",
                stopFlag: currentBusPosition["stopFlag"] ?? "",
                trnstnid: currentBusPosition["trnstnid"] ?? "",
                vehId: currentBusPosition["vehId"] ?? ""
            )
            busPositions.append(busPosition)
            currentBusPosition.removeAll()
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(busPositions)
    }
}
import Foundation

// 서울 버스 위치를 가져오는 함수
func fetchSeoulBusLocation(busRouteId: String, completion: @escaping ([BusPosition]?, String?) -> Void) {


        // 여기서 API 호출에 사용
        let urlString = "http://ws.bus.go.kr/api/rest/buspos/getBusPosByRtid?serviceKey=B%2FSwHGsQuvan%2F%2Fs6M6QvZooclQm9QpSHe%2BqbWjT4xPwDgHNXOES93T9i1%2BDKEJPWfCgcTf12X64bS9A42fFRkA%3D%3D&busRouteId=\(busRouteId)"
    
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }
    
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, "데이터를 가져오는 데 실패했습니다: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            let parser = BusPosXMLParser()
            parser.completionHandler = { busPositions in
                completion(busPositions, nil)
            }
            parser.parse(data: data)
        }.resume()
        
}
