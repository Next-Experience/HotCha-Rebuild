//
//  StopAlarmView.swift
//  HotCha
//
//  정류장(또는 장소 주변 정류장)을 지도에서 고르고 거리 기준 알람을 맞추는 화면.
//

import MapKit
import SwiftUI

struct StopAlarmView: View {
    /// 지도를 처음 맞출 중심. 정류장 검색이면 그 정류장, 장소 검색이면 그 장소다.
    let title: String
    let center: CLLocationCoordinate2D
    /// 정류장 검색으로 들어왔을 때 미리 골라 둘 정류장
    let initialStop: BusStopRecord?
    /// 정류장 즐겨찾기에서 왔다. 화면을 열자마자 마지막에 고른 알람 거리로 안내를 시작한다.
    var startsImmediately = false
    /// 즐겨찾기에 넣을 정류장을 지도에서 확인하는 중이다. 알람 대신 「저장」을 보여 주고, 누르면 고른 정류장과 이름을 넘긴다.
    var onSaveBookmark: ((BusStopRecord, String) -> Void)?
    /// 즐겨찾기 이름을 직접 붙인다(집 · 회사가 아닌 즐겨찾기). 비워 두면 정류장 이름을 쓴다.
    var asksBookmarkName = false

    /// 정류장 알람은 화면을 벗어나도 이어진다. 앱 전체가 하나를 나눠 쓴다.
    @Environment(\.dismiss) private var dismiss
    /// 뒤로 가기를 누르는 순간 false 가 된다. onDisappear 는 화면이 다 빠진 뒤에야 불려 시트가 늦게 내려간다.
    @Environment(\.isPresented) private var isPresented
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: StopAlarmViewModel
    @EnvironmentObject private var routeAlarm: RouteAlarmSession
    @AppStorage("stopAlarmRadius") private var alarmRadius: Double = 500
    /// 기차역은 시속 100~300km 로 다가와서 버스 정류장과 반경을 따로 둔다.
    @AppStorage("trainAlarmRadius") private var trainRadius: Double = 10_000

    @State private var candidates: [BusStopRecord] = []
    @State private var selectedStopID: String?
    @State private var camera: MapCameraPosition
    @State private var showsSheet = false
    @State private var bookmarkName = ""

    private static let radiusOptions: [Double] = [300, 500, 1000]
    static let trainRadiusOptions: [Double] = [3_000, 5_000, 10_000, 20_000]
    /// 길 건너편·같은 이름의 다른 정류장까지 보이도록 주변을 함께 불러온다.
    private static let candidateRadius: CLLocationDistance = 400

    init(
        stop: BusStopRecord,
        startsImmediately: Bool = false,
        asksBookmarkName: Bool = false,
        onSaveBookmark: ((BusStopRecord, String) -> Void)? = nil
    ) {
        self.startsImmediately = startsImmediately
        self.asksBookmarkName = asksBookmarkName
        self.onSaveBookmark = onSaveBookmark
        self.title = stop.name
        self.center = stop.coordinate
        self.initialStop = stop
        _selectedStopID = State(initialValue: stop.id)
        _candidates = State(initialValue: [stop])
        _camera = State(initialValue: Self.camera(for: stop.coordinate))
    }

    init(placeName: String, coordinate: CLLocationCoordinate2D) {
        self.title = placeName
        self.center = coordinate
        self.initialStop = nil
        _camera = State(initialValue: Self.camera(for: coordinate))
    }

    private static func camera(for coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 0)
        -> MapCameraPosition
    {
        let span = max(700, radius * 2.6)
        return .region(
            MKCoordinateRegion(center: coordinate, latitudinalMeters: span, longitudinalMeters: span))
    }

    /// 고른 정류장을 맨 뒤에 둔 후보 목록. 지도는 뒤에 그린 것을 위에 올린다.
    private var orderedCandidates: [BusStopRecord] {
        candidates.filter { $0.id != selectedStopID } + (selectedStop.map { [$0] } ?? [])
    }

    private var selectedStop: BusStopRecord? {
        candidates.first { $0.id == selectedStopID }
    }

    /// 기차역을 열었다. 주변 버스 정류장을 후보로 늘어놓지 않고, 알람 반경도 km 단위다.
    private var isTrain: Bool { initialStop?.isTrainStation == true }

    /// 지금 화면의 알람 반경. 정류장과 기차역이 따로 기억한다.
    private var radius: Double { isTrain ? trainRadius : alarmRadius }

    private var radiusSelection: Binding<Double> { isTrain ? $trainRadius : $alarmRadius }

    /// 시트 높이. 바뀌지 않으므로 지도의 안쪽 여백도 이 값으로 고정한다.
    private static let sheetHeight: CGFloat = 300

    /// `showsSheet` 는 시트든 패널이든 카드를 보여 줄지다. 시트로 띄우는 것은 좁은 화면에서만이다.
    /// 시스템이 넘기는 값은 받지 않는다. 펼칠 때 시트를 내리며 false 를 넘기는데, 패널로 옮겨 갔을 뿐이다.
    /// 시트는 끌어 내릴 수 없고(`interactiveDismissDisabled`), 닫는 곳은 모두 `showsSheet` 를 직접 바꾼다.
    private var sheetIsPresented: Binding<Bool> {
        Binding(get: { showsSheet && !usesSidePanel }, set: { _ in })
    }

    private var usesSidePanel: Bool { horizontalSizeClass == .regular }

    private static let sidePanelWidth: CGFloat = 380

    private var cardScroll: some View {
        ScrollView {
            bottomCard
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    var body: some View {
        HStack(spacing: 0) {
            // 가로가 넓으면(펼친 아이폰 듀오) 시트 대신 지도 왼쪽에 같은 카드를 둔다.
            if usesSidePanel && showsSheet {
                cardScroll
                    .frame(width: Self.sidePanelWidth)
                Divider()
                    .ignoresSafeArea()
            }
            map
                // 지도는 화면 전체를 덮는다. 시트가 덮는 만큼 안쪽 여백을 둬서 고른 정류장이 시트 위로 보이는 영역 가운데에 온다.
                // 넓은 화면에서는 카드가 옆 패널에 있어 지도를 덮지 않는다.
                .safeAreaPadding(.bottom, usesSidePanel ? 0 : Self.sheetHeight)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: sheetIsPresented) {
            cardScroll
                .presentationDetents([.height(Self.sheetHeight)])
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
                .tint(Color("mainpurple"))
        }
        .onAppear {
            showsSheet = true
            viewModel.beginPreview()
        }
        // 알람 화면이 전체를 덮는 동안에는 시트를 내려 둔다.
        .onChange(of: viewModel.isRinging) { _, ringing in
            showsSheet = !ringing
        }
        .onReceive(NotificationCenter.default.publisher(for: .alarmGuidanceFinished)) { _ in
            showsSheet = false
            dismiss()
        }
        .task {
            let nearby =
                isTrain ? [] : await BusDatabase.shared.stops(near: center, radius: Self.candidateRadius)
            // 미리 고른 정류장이 반경 계산에서 빠지는 일이 없도록 합친다.
            candidates = (initialStop.map { [$0] } ?? []) + nearby.filter { $0.id != initialStop?.id }
            if !isSavingBookmark, let running = viewModel.runningStop {
                // 이미 안내 중이면 다른 정류장을 열어도 안내 중인 정류장을 보여 준다.
                candidates = [running] + candidates.filter { $0.id != running.id }
                selectedStopID = running.id
            } else if selectedStopID == nil {
                selectedStopID = candidates.first?.id
            }
            viewModel.select(selectedStop)
            if let stop = selectedStop {
                camera = Self.camera(for: stop.coordinate, radius: radius)
            }
            // 이미 알람 거리 안이거나 버스 안내가 진행 중이면 시작하지 않고 화면만 연다.
            if startsImmediately, let stop = selectedStop, !viewModel.isRunning, !routeAlarm.isRunning,
                !isAlreadyInside
            {
                viewModel.start(stop: stop, radius: radius)
            }
        }
        .onChange(of: selectedStopID) { _, _ in
            viewModel.select(selectedStop)
        }
        .onChange(of: isPresented) { _, presented in
            if !presented { showsSheet = false }
        }
        .onDisappear {
            showsSheet = false
            viewModel.endPreview()
        }
    }

    // MARK: - 지도

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()

            if initialStop == nil {
                Marker(title, systemImage: "mappin", coordinate: center)
                    .tint(.gray)
            }

            if !isSavingBookmark, let stop = selectedStop {
                MapCircle(center: stop.coordinate, radius: radius)
                    .foregroundStyle(Color("mainpurple").opacity(0.12))
                    .stroke(Color("mainpurple").opacity(0.6), lineWidth: 1)
            }

            // 고른 정류장이 다른 핀에 가리지 않도록 맨 마지막에 그린다.
            ForEach(orderedCandidates) { stop in
                let isSelected = stop.id == selectedStopID
                Annotation(stop.name, coordinate: stop.coordinate, anchor: .center) {
                    StopPin(isSelected: isSelected, isTrain: stop.isTrainStation)
                        .onTapGesture {
                            // 알람 중에는 목적지를 바꾸지 않는다. 즐겨찾기를 고르는 중이면 안내와 상관없다.
                            guard isSavingBookmark || !viewModel.isRunning else { return }
                            selectedStopID = stop.id
                        }
                }
                .annotationTitles(isSelected ? .automatic : .hidden)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: radius) { _, _ in
            // 알람 반경 원이 화면에 다 들어오도록 맞춘다.
            guard let stop = selectedStop else { return }
            withAnimation {
                camera = Self.camera(for: stop.coordinate, radius: radius)
            }
        }
    }

    // MARK: - 하단 카드

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let stop = selectedStop {
                Text(stop.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle(for: stop))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                if isSavingBookmark {
                    bookmarkSection(stop: stop)
                } else if viewModel.isRunning {
                    runningSection
                } else {
                    setupSection(stop: stop)
                }
            } else {
                Text("주변에 정류장이 없어요")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text("다른 장소나 정류장 이름으로 다시 검색해 보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 28, leading: 20, bottom: 20, trailing: 20))
    }

    private func setupSection(stop: BusStopRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("얼마나 앞에서 알려드릴까요?")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 20)

            Picker("알람 거리", selection: radiusSelection) {
                ForEach(isTrain ? Self.trainRadiusOptions : Self.radiusOptions, id: \.self) { option in
                    Text(StopAlarmViewModel.format(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 10)

            let canStart = !isAlreadyInside && !routeAlarm.isRunning
            Button {
                viewModel.start(stop: stop, radius: radius)
            } label: {
                Text(startTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canStart)
            .padding(.top, 16)
        }
    }

    private var isSavingBookmark: Bool { onSaveBookmark != nil }

    /// 즐겨찾기로 저장하기 전 확인. 길 건너편 같은 이름의 정류장과 헷갈리지 않게 지도에서 보고 고른다.
    private func bookmarkSection(stop: BusStopRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isTrain ? "지도에서 맞는 역인지 확인하세요." : "지도에서 맞는 정류장인지 확인하세요. 다른 핀을 누르면 바뀌어요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 20)

            if asksBookmarkName {
                TextField("즐겨찾기 이름 (비우면 \(stop.name))", text: $bookmarkName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 12)
            }

            Button {
                onSaveBookmark?(stop, bookmarkName)
            } label: {
                Text(isTrain ? "이 역으로 저장" : "이 정류장으로 저장")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 16)
        }
    }

    private var runningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(viewModel.distance.map(StopAlarmViewModel.format) ?? "위치 확인 중")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color("mainpurple"))
                if viewModel.distance != nil {
                    Text("남았어요")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 20)

            Text("\(StopAlarmViewModel.format(viewModel.radius)) 앞에서 알려드릴게요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            // 노선 시트와 같은 시스템 글라스 버튼
            FinishGuidanceButton { viewModel.stop() }
            .padding(.top, 16)
        }
    }

    private var startTitle: String {
        if routeAlarm.isRunning { return "버스 안내가 진행 중이에요" }
        return isAlreadyInside ? "이미 알람 거리 안에 있어요" : "알람 시작"
    }

    private var isAlreadyInside: Bool {
        guard let distance = viewModel.distance else { return false }
        return distance <= radius
    }

    private func subtitle(for stop: BusStopRecord) -> String {
        var parts = [stop.cityName]
        if !stop.arsNumber.isEmpty {
            parts.append("정류장 번호 \(stop.arsNumber)")
        }
        if !viewModel.isRunning, let distance = viewModel.distance {
            parts.append("현재 위치에서 \(StopAlarmViewModel.format(distance))")
        }
        return parts.joined(separator: " · ")
    }

}

/// 지도 위 정류장 핀
private struct StopPin: View {
    let isSelected: Bool
    var isTrain = false

    var body: some View {
        Image(systemName: isTrain ? "train.side.front.car" : "bus.fill")
            .font(.system(size: isSelected ? 18 : 11, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .frame(width: isSelected ? 42 : 26, height: isSelected ? 42 : 26)
            .background(Circle().fill(isSelected ? Color("mainpurple") : Color.white))
            .overlay(
                Circle().stroke(
                    isSelected ? Color.white : Color.secondary.opacity(0.4), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            // 작은 핀도 누르기 쉽게 터치 영역을 넓힌다.
            .padding(6)
            .contentShape(Circle())
    }
}
