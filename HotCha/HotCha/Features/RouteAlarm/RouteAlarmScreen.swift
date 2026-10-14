//
//  RouteAlarmScreen.swift
//  HotCha
//
//  노선 알람 화면. 지도에 노선을 그리고, 정류장 고르기와 안내는 시스템 시트에서 한다.
//  안내 중에는 지도가 내 위치를 따라가고, 시트는 화면 절반에서 지금 상황을 보여 준다.
//

import MapKit
import SwiftData
import SwiftUI

struct RouteAlarmScreen: View {
    enum Mode: Equatable {
        /// 도착 정류장을 골라 안내를 시작한다. 정류장 ID 를 주면(즐겨찾기·이용 기록) 고르지 않고 바로 시작한다.
        case alarm(startingAt: String?)
        /// 안내 없이 즐겨찾기만 저장한다. 종류는 "집" · "회사" · 그 밖의 값(직접 이름 붙임).
        case saveBookmark(type: String)
    }

    let bus: Bus_info_seoul
    let mode: Mode
    /// 즐겨찾기를 저장한 뒤 불린다. 이 화면을 연 쪽이 닫는다.
    var onBookmarkSaved: () -> Void = {}

    @EnvironmentObject private var session: RouteAlarmSession
    @EnvironmentObject private var stopAlarm: StopAlarmViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var camera: MapCameraPosition = .automatic
    @State private var showsSheet = false
    @State private var detent: PresentationDetent = .medium
    @State private var asksToReplaceRunningAlarm = false
    /// 화면을 열 때의 내 위치. 정류장을 고르는 동안 「탑승」 정류장을 미리 보여 주는 데 쓴다.
    @State private var openedAt: CLLocation?

    var body: some View {
        GeometryReader { proxy in
            map
                // 지도는 늘 화면 전체를 덮고 시트만 움직인다. 안쪽 여백은 중간 높이 시트가 덮는 만큼으로 **고정**한다 —
                // 시트 높이를 따라가게 두면 시트를 끌 때마다 지도 가운데와 Apple 표시가 함께 오르내리며 지도가 다시 그려진다.
                // 지도는 이 여백 위로 보이는 영역을 기준으로 가운데를 잡는다.
                .safeAreaPadding(.bottom, Self.mediumSheetCover(in: proxy.size.height))
        }
        .navigationTitle("\(bus.busRouteNm)번")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showsSheet) {
            RouteAlarmSheet(
                bus: bus,
                mode: mode,
                detent: $detent,
                onFinish: {
                    showsSheet = false
                    dismiss()
                },
                onBookmarkSaved: {
                    showsSheet = false
                    onBookmarkSaved()
                }
            )
            .environmentObject(session)
            .environmentObject(stopAlarm)
            .presentationDetents([Self.peekDetent, .medium, Self.tallDetent], selection: $detent)
            // 끝까지 올려도 뒤의 지도가 어두워지거나 하얗게 바뀌지 않게, 어느 높이에서든 뒤를 그대로 둔다.
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
        .confirmationDialog(
            "다른 버스의 안내가 진행 중이에요",
            isPresented: $asksToReplaceRunningAlarm,
            titleVisibility: .visible
        ) {
            Button("끝내고 \(bus.busRouteNm)번으로 시작", role: .destructive) {
                session.finish(in: modelContext)
                prepare()
            }
            Button("그대로 두기", role: .cancel) { dismiss() }
        }
        .onAppear {
            if session.isRunning && !session.isRunning(for: bus) {
                asksToReplaceRunningAlarm = true
            } else {
                prepare()
            }
        }
        .onDisappear {
            showsSheet = false
            session.discardIfIdle()
        }
        .onChange(of: session.destinationIndex) { _, _ in
            guard !session.isRunning else { return }
            focusOnTrip()
        }
        .onChange(of: session.isRunning) { _, running in
            if running { followUser() }
        }
        // 알람 화면이 전체를 덮는 동안에는 시트를 내려 둔다.
        .onChange(of: session.alarmIsRinging) { _, ringing in
            showsSheet = !ringing
        }
        .onReceive(NotificationCenter.default.publisher(for: .alarmGuidanceFinished)) { _ in
            showsSheet = false
            dismiss()
        }
    }

    /// 가장 낮게 내린 시트. 남은 정류장 수만 보인다.
    static let peekDetent = PresentationDetent.height(150)
    /// 가장 높이 올린 시트. `.large` 는 뒤 화면을 바꿔 버려서 화면 끝까지 올리지 않는다.
    private static let tallDetent = PresentationDetent.fraction(0.92)

    /// 중간 높이 시트가 지도 아래쪽을 덮는 높이. 시트는 화면의 절반쯤인데, 지도 영역은 내비게이션 바 아래부터라 조금 더 덮인다.
    private static func mediumSheetCover(in height: CGFloat) -> CGFloat {
        height * 0.55
    }

    // MARK: - 지도

    private var map: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom]) {
            UserAnnotation()

            // 노선 전체는 옅게, 지나온 구간은 회색, 지금(또는 탈 곳)부터 내릴 정류장까지는 진하게 잇는다.
            if session.stops.count > 1 {
                MapPolyline(coordinates: session.stops.map(Self.coordinate))
                    .stroke(Color("mainpurple").opacity(0.25), style: Self.lineStyle(width: 4))
            }
            if passed.count > 1 {
                MapPolyline(coordinates: passed.map(Self.coordinate))
                    .stroke(Color.gray.opacity(0.55), style: Self.lineStyle(width: 5))
            }
            if highlighted.count > 1 {
                MapPolyline(coordinates: highlighted.map(Self.coordinate))
                    .stroke(Color("mainpurple"), style: Self.lineStyle(width: 6))
            }

            // 정류장 사이마다 진행 방향 화살표를 둔다. 같은 길을 오가는 노선에서 상행·하행이 헷갈리지 않는다.
            ForEach(arrows) { arrow in
                Annotation("", coordinate: arrow.coordinate, anchor: .center) {
                    DirectionArrowView(isOnTheWay: arrow.isOnTheWay)
                        .rotationEffect(.degrees(arrow.bearing))
                        .allowsHitTesting(false)
                }
            }

            // 정류장마다 점을 찍는다. 눌러서 내릴 정류장으로 고를 수 있다.
            ForEach(Array(session.stops.enumerated()), id: \.offset) { index, stop in
                if !markedIndices.contains(index) {
                    Annotation(stop.stationNm, coordinate: Self.coordinate(stop), anchor: .center) {
                        StopDot(style: dotStyle(at: index, stop: stop))
                            .onTapGesture { select(index) }
                    }
                    .annotationTitles(.hidden)
                }
            }

            if let index = boardingIndex, session.stops.indices.contains(index) {
                Annotation("탑승", coordinate: Self.coordinate(session.stops[index]), anchor: .center) {
                    IconPin(systemImage: "figure.wave", isFilled: false)
                }
                .annotationTitles(.hidden)
            }
            if let index = alarmIndex, session.stops.indices.contains(index) {
                Annotation("알림", coordinate: Self.coordinate(session.stops[index]), anchor: .center) {
                    IconPin(systemImage: "bell.fill", isFilled: false)
                }
                .annotationTitles(.hidden)
            }
            if let stop = session.destinationStop {
                // 점과 이름표를 따로 둔다. 이름표의 꼬리 끝이 정류장 점 바로 위에 온다.
                Annotation(stop.stationNm, coordinate: Self.coordinate(stop), anchor: .center) {
                    IconPin(systemImage: "flag.fill", isFilled: true)
                }
                .annotationTitles(.hidden)
                Annotation("", coordinate: Self.coordinate(stop), anchor: .bottom) {
                    DestinationCallout(name: stop.stationNm, detail: calloutDetail(for: stop))
                        .allowsHitTesting(false)
                }
            }
        }
        // 화살표는 북쪽이 위라고 보고 돌린다. 지도를 돌리지 못하게 해서 방향이 어긋나지 않게 한다.
        .mapControls {
            MapUserLocationButton()
        }
        .animation(.spring(duration: 0.3), value: session.destinationIndex)
    }

    private static func lineStyle(width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    /// 출발점: 안내 중이면 지금 정류장, 고르는 중이면 탈 정류장(모르면 기점)
    private var tripStart: Int {
        session.currentIndex ?? boardingIndex ?? 0
    }

    /// 출발점부터 내릴 정류장까지의 자리
    private var onTheWay: ClosedRange<Int>? {
        guard let destination = session.destinationIndex else { return nil }
        return min(tripStart, destination)...destination
    }

    private var highlighted: [BusStop] {
        guard let range = onTheWay, session.stops.indices.contains(range.upperBound) else { return [] }
        return Array(session.stops[range])
    }

    /// 안내 중 탄 정류장부터 지금 정류장까지. 지나온 길이다.
    private var passed: [BusStop] {
        guard session.isRunning, let current = session.currentIndex else { return [] }
        let start = min(session.boardedIndex ?? current, current)
        return Array(session.stops[start...current])
    }

    /// 고르는 중에만 보이는 「탑승」 정류장. 안내 중에는 내 위치가 그 자리를 대신한다.
    private var boardingIndex: Int? {
        guard !session.isRunning, let openedAt else { return nil }
        let index = session.boardingIndex(near: openedAt)
        return index == session.destinationIndex ? nil : index
    }

    private var alarmIndex: Int? {
        guard session.destinationStop != nil, let stop = session.alarmStop else { return nil }
        let index = session.stops.firstIndex { $0.station == stop.station && $0.seq == stop.seq }
        return index == session.destinationIndex ? nil : index
    }

    /// 따로 핀을 꽂는 정류장. 그 자리에는 점을 찍지 않는다.
    private var markedIndices: Set<Int> {
        Set([session.destinationIndex, alarmIndex, boardingIndex].compactMap { $0 })
    }

    private func dotStyle(at index: Int, stop: BusStop) -> StopDot.Style {
        guard RouteAlarmSession.isSelectable(stop) else { return .unselectable }
        if session.isRunning, let current = session.currentIndex {
            if index == current { return .current }
            if index < current { return .passed }
        }
        if onTheWay?.contains(index) == true { return .onTheWay }
        return .offRoute
    }

    private func calloutDetail(for stop: BusStop) -> String {
        if session.isRunning {
            guard let remaining = session.remainingStops else { return "내릴 정류장" }
            if remaining > 0 { return "\(remaining)정류장 남음" }
            return remaining == 0 ? "이번 정류장" : "\(-remaining)정류장 지남"
        }
        var parts: [String] = []
        if stop.stationNo > 0 { parts.append(String(format: "%05d", stop.stationNo)) }
        if let range = onTheWay, boardingIndex != nil, range.count > 1 {
            parts.append("\(range.count - 1)정류장 이동")
        } else {
            parts.append("내릴 정류장")
        }
        return parts.joined(separator: " · ")
    }

    /// 이웃한 두 정류장의 한가운데에 놓는 방향 화살표
    private struct DirectionArrow: Identifiable {
        let id: Int
        let coordinate: CLLocationCoordinate2D
        /// 북쪽을 0도로 시계 방향으로 잰 진행 방향
        let bearing: Double
        let isOnTheWay: Bool
    }

    private var arrows: [DirectionArrow] {
        let stops = session.stops
        guard stops.count > 1 else { return [] }
        let range = onTheWay
        let current = session.isRunning ? session.currentIndex : nil
        return (0..<(stops.count - 1)).compactMap { index in
            // 지나온 구간에는 방향을 알릴 필요가 없다.
            if let current, index < current { return nil }
            // 내릴 정류장을 고른 뒤에는 가는 길에만 둔다. 되돌아오는 노선이 겹치면 화살표가 엉킨다.
            if let range, !(range.contains(index) && range.contains(index + 1)) { return nil }
            let from = Self.coordinate(stops[index])
            let to = Self.coordinate(stops[index + 1])
            // 너무 붙은 정류장 사이에는 화살표가 점을 가린다.
            let meters = CLLocation(latitude: from.latitude, longitude: from.longitude)
                .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
            guard meters > 120 else { return nil }

            let lat1 = from.latitude * .pi / 180
            let lat2 = to.latitude * .pi / 180
            let deltaLon = (to.longitude - from.longitude) * .pi / 180
            let y = sin(deltaLon) * cos(lat2)
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
            return DirectionArrow(
                id: index,
                coordinate: CLLocationCoordinate2D(
                    latitude: (from.latitude + to.latitude) / 2,
                    longitude: (from.longitude + to.longitude) / 2
                ),
                bearing: atan2(y, x) * 180 / .pi,
                isOnTheWay: range != nil
            )
        }
    }

    // MARK: - 동작

    /// 지도에서 정류장을 눌러 내릴 정류장으로 고른다. 안내 중에는 바꾸지 않는다.
    private func select(_ index: Int) {
        guard !session.isRunning, RouteAlarmSession.isSelectable(session.stops[index]) else { return }
        session.destinationIndex = index
        detent = .medium
    }

    /// 정류장 목록을 받고 시트를 올린다. 안내 중인 노선이면 받지 않고 그대로 이어서 보여 준다.
    private func prepare() {
        showsSheet = true
        detent = .medium
        openedAt = CLLocationManager().location
        guard !session.isRunning(for: bus) else {
            followUser()
            return
        }
        var startingAt: String?
        if case .alarm(let stationId) = mode { startingAt = stationId }
        session.load(bus, startingAt: startingAt) {
            // 즐겨찾기·이용 기록에서 왔으면 도착 정류장이 정해져 있다. 바로 시작한다.
            focusOnStart()
            if startingAt != nil, session.destinationIndex != nil {
                // 안내는 한 번에 하나다. 정류장 알람이 돌고 있으면 끝내고 넘어온다.
                stopAlarm.stop()
                session.start()
            }
        }
    }

    /// 노선 전체를 한 화면에 넣으면 정류장이 뭉쳐 고를 수 없다. 내 위치에서 가장 가까운 정류장 근처로 연다.
    private func focusOnStart() {
        guard session.destinationIndex == nil, let first = session.stops.first else { return }
        let nearest = openedAt.flatMap { location in
            session.stops.min {
                location.distance(from: CLLocation(latitude: $0.gpsY, longitude: $0.gpsX))
                    < location.distance(from: CLLocation(latitude: $1.gpsY, longitude: $1.gpsX))
            }
        }
        camera = Self.region(around: [nearest ?? first], minimumMeters: 3_000)
    }

    /// 내릴 정류장을 고르면 탈 곳부터 내릴 곳까지가 한 화면에 들어오게 맞춘다.
    private func focusOnTrip() {
        guard let range = onTheWay else { return }
        withAnimation { camera = Self.region(around: Array(session.stops[range]), minimumMeters: 1_200) }
    }

    /// 안내 중에는 내 위치를 따라간다. 지도를 움직이면 멈추고, 위치 버튼으로 다시 따라간다.
    private func followUser() {
        let fallback = (session.currentStop ?? session.destinationStop).map {
            Self.region(around: [$0], minimumMeters: 1_500)
        } ?? .automatic
        withAnimation { camera = .userLocation(followsHeading: false, fallback: fallback) }
    }

    private static func coordinate(_ stop: BusStop) -> CLLocationCoordinate2D {
        // API 는 경도를 gpsX, 위도를 gpsY 로 준다.
        CLLocationCoordinate2D(latitude: stop.gpsY, longitude: stop.gpsX)
    }

    /// 정류장들이 모두 보이는 영역. 시트에 가리는 부분은 지도의 안쪽 여백(safeAreaPadding)이 뺀다.
    private static func region(around stops: [BusStop], minimumMeters: CLLocationDistance) -> MapCameraPosition {
        let coordinates = stops.map(coordinate)
        guard let first = coordinates.first else { return .automatic }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for point in coordinates {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        // 이름표가 위로 올라오므로 위아래를 넉넉히 둔다.
        let metersPerDegree = 111_000.0
        let height = max((maxLat - minLat) * metersPerDegree * 1.6, minimumMeters)
        let width = max(
            (maxLon - minLon) * metersPerDegree * cos(center.latitude * .pi / 180) * 1.4, minimumMeters)
        return .region(MKCoordinateRegion(center: center, latitudinalMeters: height, longitudinalMeters: width))
    }
}

// MARK: - 지도 위 표시

/// 지도 위 정류장 점
private struct StopDot: View {
    enum Style {
        /// 지금(또는 탈 곳)과 내릴 정류장 사이
        case onTheWay
        /// 그 밖의 노선 위 정류장
        case offRoute
        /// 안내 중 이미 지나온 정류장
        case passed
        /// 안내 중 지금 있는 정류장
        case current
        /// 버스가 서지 않는 정류장
        case unselectable
    }

    let style: Style

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(stroke, lineWidth: lineWidth))
            .shadow(color: .black.opacity(style == .onTheWay || style == .current ? 0.18 : 0), radius: 2, y: 1)
            // 작은 점도 누르기 쉽게 터치 영역을 넓힌다.
            .padding(10)
            .contentShape(Circle())
    }

    private var size: CGFloat {
        switch style {
        case .current: return 16
        case .onTheWay: return 13
        case .offRoute: return 10
        case .passed, .unselectable: return 8
        }
    }

    private var fill: Color {
        style == .current ? Color("mainpurple") : .white
    }

    private var stroke: Color {
        switch style {
        case .current: return .white
        case .onTheWay: return Color("mainpurple")
        case .offRoute: return Color("mainpurple").opacity(0.45)
        case .passed: return .gray.opacity(0.6)
        case .unselectable: return .secondary.opacity(0.35)
        }
    }

    private var lineWidth: CGFloat {
        switch style {
        case .current: return 3
        case .onTheWay: return 3.5
        default: return 2.5
        }
    }
}

/// 노선 위의 진행 방향 화살표
private struct DirectionArrowView: View {
    let isOnTheWay: Bool

    var body: some View {
        Image(systemName: "chevron.up")
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 15, height: 15)
            .background(Circle().fill(Color("mainpurple").opacity(isOnTheWay ? 1 : 0.5)))
    }
}

/// 알림 · 탑승 · 도착 정류장에 꽂는 동그란 핀
private struct IconPin: View {
    let systemImage: String
    /// 채운 핀은 도착 정류장 하나뿐이다.
    let isFilled: Bool

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: isFilled ? 13 : 12, weight: .bold))
            .foregroundStyle(isFilled ? Color.white : Color("mainpurple"))
            .frame(width: isFilled ? 30 : 26, height: isFilled ? 30 : 26)
            .background(Circle().fill(isFilled ? Color("mainpurple") : Color.white))
            .overlay(Circle().stroke(isFilled ? Color.white : Color("mainpurple"), lineWidth: isFilled ? 3 : 2))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            .accessibilityHidden(true)
    }
}

/// 도착 정류장 위에 뜨는 이름표. 꼬리 끝이 핀 바로 위를 가리킨다.
private struct DestinationCallout: View {
    let name: String
    let detail: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption.weight(.medium))
                    .opacity(0.85)
            }
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Color("mainpurple"),
                in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
            )

            CalloutTail()
                .fill(Color("mainpurple"))
                .frame(width: 14, height: 7)
        }
        .fixedSize()
        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        // 핀(지름 30)의 위쪽 끝보다 조금 위에 꼬리가 오게 한다.
        .padding(.bottom, 19)
        .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
    }
}

/// 아래를 가리키는 삼각형
private struct CalloutTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
