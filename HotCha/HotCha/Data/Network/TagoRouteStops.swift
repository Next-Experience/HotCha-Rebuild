//
//  TagoRouteStops.swift
//  HotCha
//
//  Created by 문재윤 on 5/20/25.
//

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
    guard let serviceKey = BusAPI.serviceKey else {
        completion([], "API 키가 설정되지 않았습니다.")
        return
    }

    let urlString = "https://apis.data.go.kr/1613000/BusRouteInfoInqireService/getRouteAcctoThrghSttnList?serviceKey=\(serviceKey)&_type=xml&cityCode=\(cityCode)&routeId=\(routeId)&numOfRows=9999&pageNo=1"
    
    guard let url = URL(string: urlString) else {
        completion([], "URL 생성 실패")
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion([], error.localizedDescription)
            return
        }

        guard let data = data else {
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
