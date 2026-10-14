//
//  StopMapScreen.swift
//  HotCha
//
//  지금 보이는 지도 영역의 정류장을 핀으로 보고, 전국 정류장을 이름이나 번호로 바로 찾는 화면.
//  핀을 누르면 아래에 그 정류장 카드가 뜬다. 목록은 없다.
//

import CoreLocation
import MapKit
import SwiftUI

struct StopMapScreen: View {
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var query = ""
    @State private var isSearchPresented = false
    /// 검색 제안으로 보여 줄 결과
    @State private var results: [BusStopRecord] = []
    @State private var isSearching = false
    /// 지금 보이는 영역의 정류장
    @State private var stops: [BusStopRecord] = []
    @State private var selectedStop: BusStopRecord?
    @State private var destinationStop: BusStopRecord?
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
    private static let searchLimit = 40

    var body: some View {
        NavigationStack {
            map
                .searchable(
                    text: $query,
                    isPresented: $isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "정류장 이름 · 번호"
                )
                .searchSuggestions { suggestions }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomPanel
                }
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
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
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

    @ViewBuilder
    private var suggestions: some View {
        if !trimmedQuery.isEmpty {
            if results.isEmpty, !isSearching {
                Text("검색 결과가 없어요")
                    .foregroundStyle(.secondary)
            }
            ForEach(results) { stop in
                Button {
                    choose(stop)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stop.name)
                            .foregroundStyle(.primary)
                        Text(detail(for: stop))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
            return
        }

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

    /// 검색 제안에서 고르면 검색을 닫고 그 정류장으로 간다. 그 지역의 정류장은 지도가 옮겨 간 뒤에 뜬다.
    private func choose(_ stop: BusStopRecord) {
        isSearchPresented = false
        query = ""
        select(stop)
    }

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

    private func select(_ stop: BusStopRecord) {
        withAnimation(.snappy) {
            selectedStop = stop
            camera = Self.camera(around: stop.coordinate, meters: 1_200)
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
