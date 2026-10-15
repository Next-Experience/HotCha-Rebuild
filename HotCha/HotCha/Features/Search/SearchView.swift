//
//  SearchView.swift
//  HotCha
//
//  Created by 문재윤 on 2/24/25.
//
import SwiftData
import SwiftUI
import MapKit
import CoreLocation

/// 검색 결과 탭
enum SearchScope: String, CaseIterable, Identifiable {
    case bus = "버스"
    case stop = "정류장"
    case train = "기차역"
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
        let coordinate = item.location.coordinate
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
    /// 이용 기록처럼 도착 정류장이 이미 정해진 노선. 고르지 않고 바로 안내를 시작한다.
    case route(Bus_info_seoul, startingAt: String)
    case stop(BusStopRecord)
    /// 정류장 즐겨찾기처럼 내릴 정류장이 정해져 있다. 정류장 알람을 바로 시작한다.
    case stopAlarm(BusStopRecord)
    case place(PlaceResult)

    var id: String {
        switch self {
        case .bus(let bus): return "bus-\(bus.city_code)-\(bus.busRouteId)"
        case .route(let bus, let stationId): return "route-\(bus.city_code)-\(bus.busRouteId)-\(stationId)"
        case .stop(let stop): return "stop-\(stop.id)"
        case .stopAlarm(let stop): return "stop-alarm-\(stop.id)"
        case .place(let place): return "place-\(place.name)-\(place.latitude)-\(place.longitude)"
        }
    }
}

struct SearchView: View {
    @Binding var textfiledValue: String
    @Binding var searchActivate: Bool
    @Binding var destination: SearchDestination?
    /// 즐겨찾기에 넣을 것을 고르는 중인가. 그때는 버스 · 정류장만 보여 준다.
    var isBookmark: Bool = false
    /// 내 위치. 가까운 지역의 버스와 가까운 정류장을 먼저 보여 주는 기준이다.
    var location: CLLocation?
    @Query(sort: \Usage_history.get_off_timestamp, order: .reverse) private var histories: [Usage_history]

    // 검색 결과 상태 관리
    @State private var buses: [Bus_info_seoul] = []
    @State private var stops: [BusStopRecord] = []
    @State private var trainStations: [TrainStation] = []
    /// 고른 기차역의 좌표를 MapKit 으로 확인하는 중인 역
    @State private var resolvingStation: TrainStation?
    @State private var showsStationError = false
    @StateObject private var placeCompleter = PlaceSearchCompleter()
    @State private var scope: SearchScope = .bus
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    /// 즐겨찾기는 노선 기준으로 저장하므로 버스만 보여준다.
    private var scopes: [SearchScope] {
        isBookmark ? [.bus, .stop, .train] : SearchScope.allCases
    }

    var body: some View {
        VStack(spacing: 0) {
            if textfiledValue.isEmpty {
                if isBookmark {
                    BookmarkSearchPrompt()
                } else {
                    recentList
                }
            } else {
                if scopes.count > 1 {
                    scopeBar
                }

                if isSearching {
                    VStack {
                        ProgressView()
                            .padding(.top, 100)
                        Text("검색 중...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else if count(of: scope) == 0 {
                    VStack {
                        Text("검색 결과가 없습니다")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            switch scope {
                            case .bus: busRows
                            case .stop: stopRows
                            case .train: trainRows
                            case .place: placeRows
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
        }
        .onAppear {
            if !textfiledValue.isEmpty && buses.isEmpty && stops.isEmpty && placeCompleter.results.isEmpty {
                scheduleSearch(textfiledValue)
            }
        }
        .onChange(of: textfiledValue) { _, newValue in
            scheduleSearch(newValue)
        }
        // 최근 기록 · 탭 · 결과 줄이 같은 왼쪽 선에 선다.
        .padding(.horizontal, 20)
        .background(.clear)
    }

    // MARK: - 검색어가 비었을 때

    /// 최근 이용 기록. 누르면 같은 곳으로 바로 이어진다.
    private var recentList: some View {
        let entries = HistoryEntry.merged(buses: histories, stops: StopAlarmHistory.load()).prefix(6)
        return ScrollView {
            LazyVStack(spacing: 0) {
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(Clay.magnifier.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        Text("버스 번호나 정류장, 기차역을 검색하세요")
                            .font(.title3.weight(.bold))
                        Text("장소 이름으로도 찾을 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
                ForEach(Array(entries)) { entry in
                    VStack(spacing: 0) {
                        HistoryRow(entry: entry)
                            .padding(.vertical, 12)
                        Divider()
                    }
                    .onTapGesture { destination = entry.destination }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - 탭

    private var scopeBar: some View {
        Picker("검색 범위", selection: $scope) {
            ForEach(scopes) { item in
                Text(isSearching ? item.rawValue : "\(item.rawValue) \(count(of: item))").tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 8)
    }

    private func count(of scope: SearchScope) -> Int {
        switch scope {
        case .bus: return buses.count
        case .stop: return stops.count
        case .train: return trainStations.count
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
                clay: .busStop,
                title: stop.name,
                detail: stop.arsNumber.isEmpty ? stop.cityName : "\(stop.cityName) · \(stop.arsNumber)"
            )
            .onTapGesture {
                destination = .stop(stop)
            }
        }
    }

    @ViewBuilder
    private var trainRows: some View {
        ForEach(trainStations) { station in
            resultRow(icon: "train.side.front.car", title: station.displayName, detail: station.detail)
                .overlay(alignment: .trailing) {
                    if resolvingStation == station {
                        ProgressView()
                            .padding(.trailing, 24)
                    }
                }
                .onTapGesture {
                    guard resolvingStation == nil else { return }
                    resolvingStation = station
                    Task {
                        let record = await TrainStationCatalog.resolve(station)
                        resolvingStation = nil
                        if let record {
                            destination = .stop(record)
                        } else {
                            showsStationError = true
                        }
                    }
                }
        }
        .alert("역 위치를 확인하지 못했어요", isPresented: $showsStationError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("역 위치는 지도에서 확인해요. 인터넷에 연결된 상태에서 다시 골라 주세요. 그래도 안 되면 아직 찾을 수 없는 역이에요.")
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
            HStack(spacing: 12) {
                ClayIcon(imageName: BusArt.imageName(for: route), size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        SearchBusUtil.CustomBusNoView(busNo: route.busRouteNm, routeType: route.routeType)
                        Text(BusDatabase.shared.cityName(for: route.city_code))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        BusTypeLabelView(busNo: route.busRouteAbrv, routeType: route.routeType)
                    }
                    Text("\(route.stStationNm) ↔︎ \(route.edStationNm)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 15)

            Divider()

        }
        .contentShape(Rectangle())
    }

    private func resultRow(icon: String, clay: Clay? = nil, title: String, detail: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let clay {
                    ClayIcon(clay: clay, size: 40)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("mainpurple"))
                        .frame(width: 40, height: 40)
                        .background(
                            Color("mainpurple").opacity(0.10),
                            in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.vertical, 12)

            Divider()
        }
        .contentShape(Rectangle())
    }

    // MARK: - 검색

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            buses = []
            stops = []
            trainStations = []
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
        // 화면이 알려 준 위치가 없으면 마지막으로 알려진 위치를 쓴다. 그것도 없으면 이름순이다.
        let location = self.location ?? CLLocationManager().location

        async let routeRecords = BusDatabase.shared.searchRoutes(searchText, near: location)
        async let stopRecords = BusDatabase.shared.searchStops(searchText, near: location)
        let (foundRoutes, foundStops) = await (routeRecords, stopRecords)
        guard !Task.isCancelled else { return }

        buses = foundRoutes.map { Bus_info_seoul(record: $0) }
        #if DEBUG
        if DevBus.matches(searchText) { buses.insert(DevBus.info, at: 0) }
        #endif
        stops = foundStops
        trainStations = TrainStationCatalog.search(searchText)
        // 버스 번호로 찾은 게 없으면 정류장 탭을 먼저 보여준다.
        if !scopes.contains(scope) || count(of: scope) == 0 {
            scope = scopes.first { count(of: $0) > 0 } ?? scope
        }
        // 「대전역」 처럼 역 이름을 그대로 쳤으면 같은 이름의 버스 정류장보다 기차역을 먼저 보여 준다.
        if buses.isEmpty, TrainStationCatalog.hasExactMatch(searchText) {
            scope = .train
        }
        isSearching = false

        // 장소는 네트워크를 타므로 내장 DB 결과와 따로, 도착하는 대로 채워진다.
        if !isBookmark {
            placeCompleter.search(searchText, near: location)
        }
    }
}

private struct BookmarkSearchPrompt: View {
    var body: some View {
        ContentUnavailableView {
            Label("버스나 정류장을 검색하세요", systemImage: "star")
        } description: {
            Text("늘 같은 버스를 타면 버스로, 오는 버스를 아무거나 타면 내릴 정류장으로 저장하세요.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 72)
    }
}
