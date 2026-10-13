//
//  SearchView.swift
//  HotCha
//
//  Created by 문재윤 on 2/24/25.
//
import SwiftUI
import MapKit
import CoreLocation

/// 검색 결과 탭
enum SearchScope: String, CaseIterable, Identifiable {
    case bus = "버스"
    case stop = "정류장"
    case place = "장소"

    var id: String { rawValue }
}

/// 좌표까지 확인된 장소. 이 주변 정류장을 지도에서 고른다.
struct PlaceResult: Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// MapKit 장소 자동완성.
/// 한국에서는 일반 검색(MKLocalSearch)이 정확한 이름에만 반응해서, 일부만 쳐도 나오는 자동완성을 쓴다.
final class PlaceSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func search(_ text: String, near location: CLLocation?) {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            completer.cancel()
            results = []
            return
        }
        if let location {
            completer.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 30_000, longitudinalMeters: 30_000)
        } else {
            // 위치를 모르면 한국 전체를 기준으로 한다.
            completer.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 36.3, longitude: 127.8),
                span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
            )
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }

    /// 자동완성 항목의 실제 좌표를 받아온다.
    static func resolve(_ completion: MKLocalSearchCompletion) async -> PlaceResult? {
        let request = MKLocalSearch.Request(completion: completion)
        guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else { return nil }
        let coordinate = item.placemark.coordinate
        return PlaceResult(name: completion.title, latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// "06212 대한민국 서울특별시 강남구 테헤란로 340" → "서울특별시 강남구 테헤란로 340"
    static func address(of completion: MKLocalSearchCompletion) -> String {
        completion.subtitle
            .replacingOccurrences(of: "대한민국", with: "")
            .replacingOccurrences(of: #"(^|[\s,])\d{5}(?=$|[\s,])"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
    }
}

/// 검색 결과를 눌렀을 때 이동할 화면.
/// 결과 줄은 검색이 닫히면 사라지므로, 이동은 사라지지 않는 MainView 가 맡는다.
enum SearchDestination: Hashable, Identifiable {
    case bus(Bus_info_seoul)
    case stop(BusStopRecord)
    case place(PlaceResult)

    var id: String {
        switch self {
        case .bus(let bus): return "bus-\(bus.city_code)-\(bus.busRouteId)"
        case .stop(let stop): return "stop-\(stop.id)"
        case .place(let place): return "place-\(place.name)-\(place.latitude)-\(place.longitude)"
        }
    }
}

struct SearchView: View {
    @Binding var textfiledValue: String
    @Binding var searchActivate: Bool
    @Binding var destination: SearchDestination?
    @Binding var isBookmark: Bool
    @Binding var type_name: String
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager

    // 검색 결과 상태 관리
    @State private var buses: [Bus_info_seoul] = []
    @State private var stops: [BusStopRecord] = []
    @StateObject private var placeCompleter = PlaceSearchCompleter()
    @State private var scope: SearchScope = .bus
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    /// 즐겨찾기는 노선 기준으로 저장하므로 버스만 보여준다.
    private var scopes: [SearchScope] {
        isBookmark ? [.bus] : SearchScope.allCases
    }

    var body: some View {
        VStack(spacing: 0) {
            if textfiledValue.isEmpty {
                if !isBookmark {
                    RecentStopsView(destination: $destination)
                }
                SearchHistoryView(isBookmark: $isBookmark, modalStateViewModel: modalStateViewModel, busStopSeoulViewModel: busStopSeoulViewModel, nearestBusViewModel: nearestBusViewModel, sheetManager: sheetManager)
            } else {
                if scopes.count > 1 {
                    scopeBar
                }

                if isSearching {
                    VStack {
                        ProgressView()
                            .padding(.top, 100)
                        Text("검색 중...")
                            .font(.pretendard(.medium, size: 14))
                            .foregroundStyle(Color("gray500"))
                        Spacer()
                    }
                } else if count(of: scope) == 0 {
                    VStack {
                        Text("검색 결과가 없습니다")
                            .font(.pretendard(.medium, size: 16))
                            .foregroundStyle(Color("gray500"))
                        Spacer()
                    }
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            switch scope {
                            case .bus: busRows
                            case .stop: stopRows
                            case .place: placeRows
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
        }
        .onAppear {
            busStopSeoulViewModel.returnToRootView = false
            if !textfiledValue.isEmpty && buses.isEmpty && stops.isEmpty && placeCompleter.results.isEmpty {
                scheduleSearch(textfiledValue)
            }
        }
        .onChange(of: textfiledValue) { _, newValue in
            scheduleSearch(newValue)
        }
        .background(Color("gray50"))
    }

    // MARK: - 탭

    private var scopeBar: some View {
        HStack(spacing: 8) {
            ForEach(scopes) { item in
                let isSelected = item == scope
                Text(isSearching ? item.rawValue : "\(item.rawValue) \(count(of: item))")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(isSelected ? Color("gray50") : Color("gray500"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(isSelected ? Color("mainpurple") : Color("gray150")))
                    .contentShape(Capsule())
                    .onTapGesture { scope = item }
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }

    private func count(of scope: SearchScope) -> Int {
        switch scope {
        case .bus: return buses.count
        case .stop: return stops.count
        case .place: return placeCompleter.results.count
        }
    }

    // MARK: - 결과 줄

    @ViewBuilder
    private var busRows: some View {
        ForEach(buses) { route in
            formatBusRoute(route)
                .onTapGesture {
                    destination = .bus(route)
                    searchActivate = false
                }
        }
    }

    @ViewBuilder
    private var stopRows: some View {
        ForEach(stops) { stop in
            resultRow(
                icon: "bus.fill",
                title: stop.name,
                detail: stop.arsNumber.isEmpty ? stop.cityName : "\(stop.cityName) · \(stop.arsNumber)"
            )
            .onTapGesture { destination = .stop(stop) }
        }
    }

    @ViewBuilder
    private var placeRows: some View {
        ForEach(placeCompleter.results, id: \.self) { completion in
            resultRow(icon: "mappin.and.ellipse", title: completion.title, detail: PlaceSearchCompleter.address(of: completion))
                .onTapGesture {
                    Task {
                        if let place = await PlaceSearchCompleter.resolve(completion) {
                            destination = .place(place)
                        }
                    }
                }
        }
    }

    func formatBusRoute(_ route: Bus_info_seoul) -> some View {
        return VStack(spacing: 0) {
            HStack {
                SearchBusUtil.CustomBusNoView(busNo: route.busRouteNm, routeType: route.routeType)
                Text(BusDatabase.shared.cityName(for: route.city_code))
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray300"))
                BusTypeLabelView(busNo: route.busRouteAbrv, routeType: route.routeType)

                Spacer()
            }
            .padding(.top, 8)

            HStack {
                Text("\(route.stStationNm) ↔︎ \(route.edStationNm)")
                    .font(.pretendard(.semibold, size: 14))
                    .foregroundStyle(Color("gray900"))
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom)

            Rectangle()
                .foregroundStyle(Color("gray100"))
                .frame(height: 1)

        }
        .contentShape(Rectangle())
    }

    private func resultRow(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("mainpurple"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("mainpurple").opacity(0.15)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(Color("gray900"))
                        .lineLimit(1)
                    Text(detail)
                        .font(.pretendard(.medium, size: 13))
                        .foregroundStyle(Color("gray400"))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.vertical, 12)

            Rectangle()
                .foregroundStyle(Color("gray100"))
                .frame(height: 1)
        }
        .contentShape(Rectangle())
    }

    // MARK: - 검색

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            buses = []
            stops = []
            placeCompleter.search("", near: nil)
            isSearching = false
            return
        }

        isSearching = true
        // 디바운싱: 0.3초 후 검색 실행
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(searchText: text)
        }
    }

    @MainActor
    private func performSearch(searchText: String) async {
        // 마지막으로 알려진 위치만 쓴다. 권한이 없으면 nil 이고, 그러면 이름순으로 나온다.
        let location = CLLocationManager().location

        async let routeRecords = BusDatabase.shared.searchRoutes(searchText, near: location)
        async let stopRecords = isBookmark ? [] : BusDatabase.shared.searchStops(searchText, near: location)
        let (foundRoutes, foundStops) = await (routeRecords, stopRecords)
        guard !Task.isCancelled else { return }

        buses = foundRoutes.map { Bus_info_seoul(record: $0) }
        stops = foundStops
        // 버스 번호로 찾은 게 없으면 정류장 탭을 먼저 보여준다.
        if !scopes.contains(scope) || count(of: scope) == 0 {
            scope = scopes.first { count(of: $0) > 0 } ?? scope
        }
        isSearching = false

        // 장소는 네트워크를 타므로 내장 DB 결과와 따로, 도착하는 대로 채워진다.
        if !isBookmark {
            placeCompleter.search(searchText, near: location)
        }
    }
}

/// 검색어가 비어 있을 때 보여주는, 최근에 알람을 맞춘 정류장
struct RecentStopsView: View {
    @Binding var destination: SearchDestination?
    @State private var stops: [BusStopRecord] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !stops.isEmpty {
                Text("최근 정류장")
                    .font(.pretendard(.medium, size: 16))
                    .foregroundColor(Color("gray300"))
                    .padding(.top, 6)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stops) { stop in
                            HStack(spacing: 6) {
                                Image(systemName: "bus.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color("mainpurple"))
                                Text(stop.name)
                                    .font(.pretendard(.semibold, size: 14))
                                    .foregroundStyle(Color("gray900"))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color("gray150")))
                            .onTapGesture { destination = .stop(stop) }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { stops = RecentStops.load() }
    }
}
