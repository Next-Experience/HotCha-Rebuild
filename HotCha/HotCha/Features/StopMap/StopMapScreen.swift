//
//  StopMapScreen.swift
//  HotCha
//
//  지금 보이는 지도 영역의 정류장을 핀으로 보고, 정류장이나 장소를 찾아 그리로 옮겨 가는 화면.
//  핀을 누르면 아래에 그 정류장 카드가 지도 위에 뜬다. 지도는 움직이지 않는다. 목록은 없다.
//

import CoreLocation
import MapKit
import SwiftUI

struct StopMapScreen: View {
    @StateObject private var locationViewModel = LocationViewModel()
    @StateObject private var placeCompleter = PlaceSearchCompleter()

    @State private var query = ""
    @State private var isSearchPresented = false
    /// 검색 제안으로 보여 줄 결과
    @State private var results: [BusStopRecord] = []
    @State private var isSearching = false
    /// 지금 보이는 영역의 정류장
    @State private var stops: [BusStopRecord] = []
    @State private var selectedStop: BusStopRecord?
    @State private var destinationStop: BusStopRecord?
    /// 검색에서 고른 장소. 지도에 표시를 꽂는다.
    @State private var place: PlaceResult?
    /// 너무 넓게 보고 있어 핀을 그리지 않는다.
    @State private var isZoomedOutTooFar = false
    @State private var searchTask: Task<Void, Never>?
    @State private var regionTask: Task<Void, Never>?
    @State private var hasCenteredOnUser = false
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            latitudinalMeters: 3_000,
            longitudinalMeters: 3_000
        )
    )

    /// 보이는 영역의 세로가 이보다 길면 핀을 그리지 않는다. 정류장이 너무 많아 한가운데만 뭉쳐 보인다.
    private static let maxVisibleSpan: CLLocationDistance = 5_000
    private static let regionLimit = 150
    private static let searchLimit = 3
    private static let placeLimit = 5

    var body: some View {
        NavigationStack {
            map
                // 카드와 검색 결과는 지도 위에 띄운다. 안전 영역을 바꾸면 뜨고 사라질 때마다 지도가 줄었다 늘었다 한다.
                .overlay(alignment: .top) {
                    if isSearchPresented, !trimmedQuery.isEmpty {
                        searchPanel
                    }
                }
                .overlay(alignment: .bottom) {
                    if !isSearchPresented {
                        bottomPanel
                    }
                }
                .searchable(
                    text: $query,
                    isPresented: $isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "정류장 이름 · 번호"
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .navigationDestination(item: $destinationStop) { stop in
                    StopAlarmView(stop: stop)
                }
                .onAppear {
                    locationViewModel.requestLocation()
                }
                .onDisappear {
                    searchTask?.cancel()
                    regionTask?.cancel()
                    locationViewModel.stopTrackingLocation()
                }
                .onChange(of: query) { _, newValue in
                    scheduleSearch(newValue)
                }
                .onReceive(locationViewModel.$location.compactMap { $0 }) { location in
                    received(location)
                }
        }
    }

    // MARK: - 지도

    private var map: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom, .rotate]) {
            UserAnnotation()

            if let place {
                Marker(place.name, systemImage: "mappin", coordinate: place.coordinate)
            }

            ForEach(pinnedStops) { stop in
                let isSelected = stop.id == selectedStop?.id
                Annotation(stop.name, coordinate: stop.coordinate, anchor: .center) {
                    StopMapPin(isSelected: isSelected)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            select(stop)
                        }
                }
                .annotationTitles(isSelected ? .automatic : .hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        // 지도를 옮기거나 확대 · 축소를 멈추면 그 영역의 정류장을 다시 찾는다.
        .onMapCameraChange(frequency: .onEnd) { context in
            loadStops(in: context.region)
        }
    }

    /// 핀으로 그릴 정류장. 고른 정류장은 영역 밖이어도 남기고, 다른 핀에 가리지 않게 맨 나중에 그린다.
    private var pinnedStops: [BusStopRecord] {
        guard let selectedStop else { return stops }
        return stops.filter { $0.id != selectedStop.id } + [selectedStop]
    }

    // MARK: - 아래 카드

    @ViewBuilder
    private var bottomPanel: some View {
        if let selectedStop {
            stopCard(selectedStop)
        } else if isZoomedOutTooFar {
            Text("지도를 확대하면 정류장이 보여요")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
                .padding(.bottom, 8)
        }
    }

    private func stopCard(_ stop: BusStopRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.name)
                        .font(.title3.weight(.bold))
                        .lineLimit(2)
                    Text(detail(for: stop))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    withAnimation(.snappy) { selectedStop = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.secondary)
                .accessibilityLabel("닫기")
            }

            Button {
                destinationStop = stop
            } label: {
                Label("정류장 알림 설정", systemImage: "bell.badge.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// "서울특별시 · 23813 · 내 위치에서 350m"
    private func detail(for stop: BusStopRecord) -> String {
        let number = stop.arsNumber.isEmpty || stop.arsNumber == "0" ? nil : stop.arsNumber
        let distance = locationViewModel.location.map {
            "내 위치에서 \(StopAlarmViewModel.format($0.distance(from: stop.location)))"
        }
        return [stop.cityName, number, distance]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    // MARK: - 검색

    /// 검색 결과. 시스템 검색 제안은 지도를 흰 화면으로 덮어서, 검색창 아래 지도 위에 글래스 패널로 띄운다.
    private var searchPanel: some View {
        ViewThatFits(in: .vertical) {
            searchRows
            ScrollView {
                searchRows
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .frame(maxHeight: 420)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var searchRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            if results.isEmpty, placeResults.isEmpty {
                Text(isSearching ? "찾는 중…" : "검색 결과가 없어요")
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            if !results.isEmpty {
                searchSectionTitle("정류장")
                ForEach(results) { stop in
                    searchRow(icon: "bus.fill", title: stop.name, detail: detail(for: stop)) {
                        choose(stop)
                    }
                }
            }
            if !placeResults.isEmpty {
                searchSectionTitle("장소")
                ForEach(placeResults, id: \.self) { completion in
                    searchRow(
                        icon: "mappin.and.ellipse",
                        title: completion.title,
                        detail: PlaceSearchCompleter.address(of: completion)
                    ) {
                        choose(completion)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeResults: [MKLocalSearchCompletion] {
        Array(placeCompleter.results.prefix(Self.placeLimit))
    }

    private func searchSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }

    private func searchRow(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("mainpurple"))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            placeCompleter.search("", near: nil)
            return
        }

        placeCompleter.search(trimmed, near: locationViewModel.location)

        isSearching = true
        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let found = await BusDatabase.shared.searchStops(
                trimmed,
                near: locationViewModel.location,
                limit: Self.searchLimit
            )
            guard !Task.isCancelled, trimmedQuery == trimmed else { return }
            results = found
            isSearching = false
        }
    }

    /// 검색에서 정류장을 고르면 검색을 닫고 그 정류장으로 간다. 그 지역의 정류장은 지도가 옮겨 간 뒤에 뜬다.
    private func choose(_ stop: BusStopRecord) {
        closeSearch()
        place = nil
        withAnimation(.snappy) {
            selectedStop = stop
            camera = Self.camera(around: stop.coordinate, meters: Self.chosenSpan)
        }
    }

    /// 검색에서 장소를 고르면 그 장소로 가서 표시를 꽂는다. 주변 정류장은 지도가 옮겨 간 뒤에 뜬다.
    private func choose(_ completion: MKLocalSearchCompletion) {
        closeSearch()
        Task { @MainActor in
            guard let found = await PlaceSearchCompleter.resolve(completion) else { return }
            withAnimation(.snappy) {
                place = found
                selectedStop = nil
                camera = Self.camera(around: found.coordinate, meters: Self.chosenSpan)
            }
        }
    }

    private func closeSearch() {
        isSearchPresented = false
        query = ""
    }

    private static let chosenSpan: CLLocationDistance = 1_200

    // MARK: - 정류장 불러오기

    private func received(_ location: CLLocation) {
        guard !hasCenteredOnUser else { return }
        hasCenteredOnUser = true
        // 이미 다른 정류장을 골라 옮겨 갔으면 내 위치로 끌어오지 않는다.
        guard selectedStop == nil else { return }
        camera = Self.camera(around: location.coordinate, meters: 1_500)
    }

    private func loadStops(in region: MKCoordinateRegion) {
        regionTask?.cancel()
        let height = region.span.latitudeDelta * 111_000
        guard height <= Self.maxVisibleSpan else {
            isZoomedOutTooFar = true
            stops = []
            return
        }
        isZoomedOutTooFar = false
        let width = region.span.longitudeDelta * 111_000 * cos(region.center.latitude * .pi / 180)
        // 보이는 사각형의 모서리까지 닿도록 대각선의 절반을 반경으로 쓴다.
        let radius = hypot(width, height) / 2
        regionTask = Task { @MainActor in
            let found = await BusDatabase.shared.stops(
                near: region.center,
                radius: radius,
                limit: Self.regionLimit
            )
            guard !Task.isCancelled else { return }
            stops = found
        }
    }

    /// 핀을 누르면 고르기만 한다. 지도는 위치도 확대도 그대로 둔다.
    private func select(_ stop: BusStopRecord) {
        withAnimation(.snappy) {
            selectedStop = stop
        }
    }

    private static func camera(around coordinate: CLLocationCoordinate2D, meters: CLLocationDistance)
        -> MapCameraPosition
    {
        .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        )
    }
}

/// 정류장 핀. 고른 것만 보라로 채우고, 나머지는 흰 바탕에 보라 아이콘이다(노선 지도의 핀과 같은 모양).
private struct StopMapPin: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "bus.fill")
            .font(.system(size: isSelected ? 16 : 11, weight: .bold))
            .foregroundStyle(isSelected ? Color.white : Color("mainpurple"))
            .frame(width: isSelected ? 38 : 26, height: isSelected ? 38 : 26)
            .background(Circle().fill(isSelected ? Color("mainpurple") : Color.white))
            .overlay(Circle().stroke(isSelected ? Color.white : Color("mainpurple"), lineWidth: isSelected ? 3 : 2))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            .animation(.snappy, value: isSelected)
    }
}

#Preview {
    StopMapScreen()
        .environmentObject(StopAlarmViewModel())
        .environmentObject(RouteAlarmSession())
}
