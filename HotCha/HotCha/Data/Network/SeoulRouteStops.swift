

import Foundation

class BusSeoulStationParserDelegate: NSObject, XMLParserDelegate {
    var parsedStations: [BusStop] = []
    private var currentElement = ""
    private var currentBusStation: BusStop?
    private var currentText = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "itemList" {
            currentBusStation = BusStop(
                busRouteId: "",
                busRouteNm: "",
                seq: 0,
                station: "",
                stationNm: "",
                gpsX: 0.0,
                gpsY: 0.0,
                stationNo: 0
            )
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    // 응답 필드를 하나씩 옮기는 switch 라 분기 수가 곧 필드 수다.
    // swiftlint:disable:next cyclomatic_complexity
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        guard var busStation = currentBusStation else { return }
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "busRouteId":
            busStation.busRouteId = trimmedText
        case "busRouteNm":
            busStation.busRouteNm = trimmedText
        case "seq":
            busStation.seq = Int(trimmedText) ?? 0
        case "station":
            busStation.station = trimmedText
        case "stationNm":
            busStation.stationNm = trimmedText
        case "gpsX":
            busStation.gpsX = Double(trimmedText) ?? 0.0
        case "gpsY":
            busStation.gpsY = Double(trimmedText) ?? 0.0
        case "stationNo":
            busStation.stationNo = Int(trimmedText) ?? 0
        // Optional 값들
        case "direction":
            busStation.direction = trimmedText
        case "section":
            busStation.section = trimmedText
        case "routeType":
            busStation.routeType = Int(trimmedText)
        case "beginTm":
            busStation.beginTm = trimmedText
        case "lastTm":
            busStation.lastTm = trimmedText
        case "posX":
            busStation.posX = Double(trimmedText)
        case "posY":
            busStation.posY = Double(trimmedText)
        case "arsId":
            busStation.arsId = Int(trimmedText)
        case "transYn":
            busStation.transYn = trimmedText
        case "trnstnid":
            busStation.trnstnid = trimmedText
        case "sectSpd":
            busStation.sectSpd = Int(trimmedText)
        case "fullSectDist":
            busStation.fullSectDist = Int(trimmedText)

        case "itemList":
            parsedStations.append(busStation)
            currentBusStation = nil
        default:
            break
        }

        currentText = ""
        currentBusStation = busStation
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("❌ XML 파싱 오류 발생: \(parseError.localizedDescription)")
    }
}

// 서울 노선의 정류장 목록을 가져오는 함수
func fetchBusStations(routeId: String, completion: @escaping ([BusStop], String?) -> Void) {
    guard let serviceKey = BusAPI.serviceKey else {
        completion([], "API 키가 설정되지 않았습니다.")
        return
    }

    let urlString = "http://ws.bus.go.kr/api/rest/busRouteInfo/getStaionByRoute?serviceKey=\(serviceKey)&busRouteId=\(routeId)"

    guard let url = URL(string: urlString) else {
        completion([], "잘못된 URL")
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion([], error.localizedDescription)
            return
        }

        guard let data = data else {
            completion([], "데이터가 없음")
            return
        }

        let parser = XMLParser(data: data)
        let busSeoulStationParserDelegate = BusSeoulStationParserDelegate()  // XML 파싱을 위한 delegate
        parser.delegate = busSeoulStationParserDelegate

        if parser.parse() {
            completion(busSeoulStationParserDelegate.parsedStations, nil)
        } else {
            completion([], "XML 파싱 실패")
        }
    }.resume()
}
