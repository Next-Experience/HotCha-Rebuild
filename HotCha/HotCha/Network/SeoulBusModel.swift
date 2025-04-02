//
//  SeoulBusModel.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//

// 서울 버스 구조체
// BusInfo는 서울이라고 생각하면 된다.

import Foundation


// BusInfo 구조체는 기존과 동일합니다.
struct BusInfo: Identifiable {
    var id: String {
        vehId // 각 버스의 ID는 vehId로 식별합니다.
    }
    var busType: String // 차량유형 (0:일반버스, 1:저상)
    var congetion: String // 차량내부 혼잡도 (0 : 없음, 3 : 여유, 4 : 보통, 5 : 혼잡, 6 : 매우혼잡)
    var dataTm: String // 제공시간
    var fullSectDist: String // 정류소간 거리
    var gpsX: Double // 맵매칭X좌표 (WGS84)
    var gpsY: Double // 맵매칭Y좌표 (WGS84)
    var isFullFlag: String // 만차여부
    var islastyn: String // 막차여부
    var isrunyn: String // 해당차량 운행여부
    var lastStTm: String // 종점도착소요시간
    var lastStnId: String // 최종정류장 ID
    var nextStId: String // 다음정류소아이디
    var nextStTm: String // 다음정류소도착소요시간
    var plainNo: String // 차량번호
    var posX: Double // 맵매칭X좌표 (GRS80)
    var posY: Double // 맵매칭Y좌표 (GRS80)
    var rtDist: String // 노선옵셋거리
    var sectDist: String // 구간옵셋거리
    var sectOrd: String // 구간순번
    var sectionId: String // 구간ID
    var stopFlag: String // 정류소도착여부 (1:도착, 0:운행중)
    var trnstnid: String // 회차지 정류소ID
    var vehId: String // 버스ID
}



// BusInfoParser 클래스는 기존과 동일하게 사용합니다.
class BusInfoParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentBusInfo: [String: String] = [:]
    private var busInfos = [BusInfo]()
    var completionHandler: (([BusInfo]) -> Void)?

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
        currentBusInfo[currentElement] = (currentBusInfo[currentElement] ?? "") + trimmedString
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "itemList" {
            guard let gpsX = Double(currentBusInfo["gpsX"] ?? ""),
                  let gpsY = Double(currentBusInfo["gpsY"] ?? ""),
                  let posX = Double(currentBusInfo["posX"] ?? ""),
                  let posY = Double(currentBusInfo["posY"] ?? "") else {
                currentBusInfo.removeAll()
                return
            }

            let busInfo = BusInfo(
                busType: currentBusInfo["busType"] ?? "",
                congetion: currentBusInfo["congetion"] ?? "",
                dataTm: currentBusInfo["dataTm"] ?? "",
                fullSectDist: currentBusInfo["fullSectDist"] ?? "",
                gpsX: gpsX,
                gpsY: gpsY,
                isFullFlag: currentBusInfo["isFullFlag"] ?? "",
                islastyn: currentBusInfo["islastyn"] ?? "",
                isrunyn: currentBusInfo["isrunyn"] ?? "",
                lastStTm: currentBusInfo["lastStTm"] ?? "",
                lastStnId: currentBusInfo["lastStnId"] ?? "",
                nextStId: currentBusInfo["nextStId"] ?? "",
                nextStTm: currentBusInfo["nextStTm"] ?? "",
                plainNo: currentBusInfo["plainNo"] ?? "",
                posX: posX,
                posY: posY,
                rtDist: currentBusInfo["rtDist"] ?? "",
                sectDist: currentBusInfo["sectDist"] ?? "",
                sectOrd: currentBusInfo["sectOrd"] ?? "",
                sectionId: currentBusInfo["sectionId"] ?? "",
                stopFlag: currentBusInfo["stopFlag"] ?? "",
                trnstnid: currentBusInfo["trnstnid"] ?? "",
                vehId: currentBusInfo["vehId"] ?? ""
            )
            busInfos.append(busInfo)
            currentBusInfo.removeAll()
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(busInfos)
    }
}


