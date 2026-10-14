//
//  BusArt.swift
//  HotCha
//
//  노선 유형에 맞는 버스 그림(Assets.xcassets/KoreanBuses)을 고른다.
//  그림은 대표 도색을 앱용으로 다시 그린 것이다. 그 노선을 실제로 그 차가 다닌다는 뜻이 아니다.
//  그림이 없는 유형은 클레이 버스를 쓴다.
//

import Foundation

enum BusArt {
    /// 창원시 도시 코드. 창원 시내버스만 하늘색 그림을 쓴다.
    private static let changwonCityCode = "38010"

    static func imageName(routeType: String, busNumber: String, cityCode: String) -> String {
        let number = busNumber.uppercased()
        // 번호가 유형보다 분명한 경우: M 은 광역급행, G 는 경기 급행이다.
        if number.hasPrefix("M") { return "HotChaBusMDoubleDecker" }
        if number.hasPrefix("G") { return "HotChaBusExpressRed" }

        switch routeType {
        // 서울 노선은 숫자 코드로 온다.
        case "1", "공항버스": return "HotChaBusAirport"
        case "2", "마을버스": return "HotChaBusVillage"
        case "3", "간선버스": return "HotChaBusSeoulTrunk"
        case "4", "지선버스": return "HotChaBusSeoulFeeder"
        case "5", "순환버스": return "HotChaBusNamsanCirculator"
        case "6", "광역버스", "좌석버스", "직행좌석버스": return "HotChaBusMetropolitanSeat"
        case "광역급행버스": return "HotChaBusMDoubleDecker"
        case "급행버스": return "HotChaBusExpressRed"
        case "농어촌(일반)버스", "농어촌(좌석)버스": return "HotChaBusRural"
        case "시외버스": return "HotChaBusIntercity"
        case "일반버스", "시내버스":
            return cityCode == changwonCityCode ? "HotChaBusChangwonCity" : "HotChaBusLocalCity"
        default:
            if cityCode == changwonCityCode { return "HotChaBusChangwonCity" }
            return Clay.bus.rawValue
        }
    }

    static func imageName(for bus: Bus_info_seoul) -> String {
        imageName(routeType: bus.routeType, busNumber: bus.busRouteNm, cityCode: bus.city_code)
    }
}
