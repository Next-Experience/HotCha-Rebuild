//
//  StopMapScreen.swift
//  HotCha
//
//  주변 정류장을 지도에서 보고, 전국 정류장을 이름이나 번호로 바로 찾는 화면.
//

import CoreLocation
import MapKit
import SwiftUI

struct StopMapScreen: View {
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var query = ""
    @State private var stops: [BusStopRecord] = []
    @State private var selectedStop: BusStopRecord?
    @State private var destinationStop: BusStopRecord?
    @State private var isLoading = true
    @State private var searchTask: Task<Void, Never>?
    @State private var hasCenteredOnUser = false
    @FocusState private var searchIsFocused: Bool
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            latitudinalMeters: 12_000,
            longitudinalMeters: 12_000
        )
    )

    private static let nearbyRadius: CLLocationDistance = 1_500
    private static let nearbyLimit = 60
    private static let searchLimit = 60

    var body: some View {
        NavigationStack {
            map
                .navigationTitle("정류장 지도")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "정류장 이름 · 번호")
                .searchFocused($searchIsFocused)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    resultsPanel
                }
                .navigationDestination(item: $destinationStop) { stop in
                    StopAlarmView(stop: stop)
                }
                .onAppear {
                    locationViewModel.requestLocation()
                }
                .onDisappear {
                    searchTask?.cancel()
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

    private var map: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom, .rotate]) {
            UserAnnotation()

            ForEach(stops) { stop in
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
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(panelTitle)
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if !stops.isEmpty {
                    Text("\(stops.count)곳")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if stops.isEmpty, !isLoading {
                emptyState
            } else if !stops.isEmpty {
                stopCarousel

                if let selectedStop {
                    Button {
                        destinationStop = selectedStop
                    } label: {
                        Label("정류장 알림 설정", systemImage: "bell.badge.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("정류장을 누르면 위치를 확인하고 알림을 설정할 수 있어요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var stopCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(stops) { stop in
                    Button {
                        select(stop)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(stop.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(subtitle(for: stop))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 210, alignment: .leading)
                        .padding(12)
                        .background(
                            stop.id == selectedStop?.id
                                ? Color("mainpurple").opacity(0.14)
                                : Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                        )
                        .overlay {
                            if stop.id == selectedStop?.id {
                                RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                                    .stroke(Color("mainpurple"), lineWidth: 1.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(query.trimmingCharacters(in: .whitespaces).isEmpty
                ? "주변 정류장을 찾을 수 없어요"
                : "검색 결과가 없어요")
                .font(.body.weight(.semibold))
            Text(query.trimmingCharacters(in: .whitespaces).isEmpty
                ? "위치를 확인한 뒤 다시 시도해 주세요."
                : "다른 정류장 이름이나 번호로 찾아보세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var panelTitle: String {
        query.trimmingCharacters(in: .whitespaces).isEmpty ? "주변 정류장" : "검색 결과"
    }

    private func subtitle(for stop: BusStopRecord) -> String {
        let number = stop.arsNumber.isEmpty || stop.arsNumber == "0" ? nil : stop.arsNumber
        return [stop.cityName, number]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func received(_ location: CLLocation) {
        guard query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !hasCenteredOnUser else { return }
        hasCenteredOnUser = true
        camera = Self.camera(around: location.coordinate, meters: 3_000)
        loadNearby(at: location.coordinate)
    }

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        selectedStop = nil

        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            if let coordinate = locationViewModel.location?.coordinate {
                loadNearby(at: coordinate)
            } else {
                stops = []
                isLoading = true
            }
            return
        }

        isLoading = true
        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let found = await BusDatabase.shared.searchStops(
                trimmed,
                near: locationViewModel.location,
                limit: Self.searchLimit
            )
            guard !Task.isCancelled, query.trimmingCharacters(in: .whitespaces) == trimmed else { return }
            stops = found
            isLoading = false
            if let first = found.first {
                camera = Self.camera(around: first.coordinate, meters: 4_000)
            }
        }
    }

    private func loadNearby(at coordinate: CLLocationCoordinate2D) {
        searchTask?.cancel()
        isLoading = true
        searchTask = Task { @MainActor in
            let nearby = await BusDatabase.shared.stops(
                near: coordinate,
                radius: Self.nearbyRadius,
                limit: Self.nearbyLimit
            )
            guard !Task.isCancelled, query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            stops = nearby
            isLoading = false
        }
    }

    private func select(_ stop: BusStopRecord) {
        searchIsFocused = false
        selectedStop = stop
        withAnimation(.snappy) {
            camera = Self.camera(around: stop.coordinate, meters: 1_800)
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

private struct StopMapPin: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "bus.fill")
            .font(.system(size: isSelected ? 16 : 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: isSelected ? 38 : 32, height: isSelected ? 38 : 32)
            .background(Color("mainpurple"), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            .animation(.snappy, value: isSelected)
    }
}

#Preview {
    StopMapScreen()
        .environmentObject(StopAlarmViewModel())
        .environmentObject(RouteAlarmSession())
}
