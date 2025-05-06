

import SwiftUI
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

// 데이터를 가져오는 함수
func fetchBusStations(routeId: String, completion: @escaping ([BusStop], String?) -> Void) {
    
    if let apiKey = getAPIKey() {
        print("API Key: \(apiKey)")
        // 여기서 API 호출에 사용
    
    let urlString = "http://ws.bus.go.kr/api/rest/busRouteInfo/getStaionByRoute?serviceKey=B%2FSwHGsQuvan%2F%2Fs6M6QvZooclQm9QpSHe%2BqbWjT4xPwDgHNXOES93T9i1%2BDKEJPWfCgcTf12X64bS9A42fFRkA%3D%3D&busRouteId=\(routeId)"
    
    guard let url = URL(string: urlString) else {
        print("🚨 잘못된 URL")
        completion([], "잘못된 URL") // URL이 잘못되었으면 빈 배열 반환
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("❌ 데이터 가져오기 실패: \(error.localizedDescription)")
            completion([], error.localizedDescription) // 데이터 가져오기 실패 시 빈 배열과 오류 메시지 반환
            return
        }
        
        guard let data = data else {
            print("❌ 데이터 없음")
            completion([], "데이터가 없음") // 데이터가 없으면 빈 배열과 오류 메시지 반환
            return
        }
        
        let parser = XMLParser(data: data)
        let busSeoulStationParserDelegate = BusSeoulStationParserDelegate()  // XML 파싱을 위한 delegate
        parser.delegate = busSeoulStationParserDelegate
        
        if parser.parse() {
            print("✅ XML 파싱 성공ㅋㅋㅋㅋㅋㅋㅋㅋ")
            completion(busSeoulStationParserDelegate.parsedStations, nil)  // 파싱된 버스 데이터를 반환
        } else {
            print("❌ XML 파싱 실패")
            completion([], "XML 파싱 실패") // 파싱 실패 시 빈 배열과 오류 메시지 반환
        }
    }.resume()
        
    } else {
        print("API Key가 없습니다.")
    }
}


