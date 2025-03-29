//
//  Constants.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

struct Constants {
    static let apiKey = "lRR0MF6ORcLObwo0%2B1E7kRXK4Jcol%2B7Tz%2FoB0%2FP2bIyexf%2BRGtBar7DAGbEwpHxIErYwRKsQMrbyew2XFV0bIg%3D%3D"
    
    struct API {
        static let baseURL = "https://apis.data.go.kr/1613000"  // HTTP에서 HTTPS로 변경
        
        // 버스 도착 정보 API
        static let busArrival = "/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList"
        
        // 버스 정류소 정보 API
        static let busStop = "/BusSttnInfoInqireService/getSttnNoList"
        
        // 버스 위치 정보 API
        static let busLocation = "/BusLcInfoInqireService/getRouteAcctoBusLcList"
        
        // 버스 노선 정보 API
        static let busRoute = "/BusRouteInfoInqireService/getRouteNoList"
        
        // 버스 노선별 정류소 목록 API
        static let routeStations = "/BusRouteInfoInqireService/getRouteAcctoThrghSttnList"
    }
}
