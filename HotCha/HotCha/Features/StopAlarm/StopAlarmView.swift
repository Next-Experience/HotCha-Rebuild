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

    /// 정류장 알람은 화면을 벗어나도 이어진다. 앱 전체가 하나를 나눠 쓴다.
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: StopAlarmViewModel
    @EnvironmentObject private var routeAlarm: RouteAlarmSession
    @AppStorage("stopAlarmRadius") private var alarmRadius: Double = 500

    @State private var candidates: [BusStopRecord] = []
    @State private var selectedStopID: String?
    @State private var camera: MapCameraPosition
    @State private var showsSheet = false

    private static let radiusOptions: [Double] = [300, 500, 1000]
    /// 길 건너편·같은 이름의 다른 정류장까지 보이도록 주변을 함께 불러온다.
    private static let candidateRadius: CLLocationDistance = 400

    init(stop: BusStopRecord) {
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

    var body: some View {
        map
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .sheet(isPresented: $showsSheet) {
                ScrollView {
                    bottomCard
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .presentationDetents([.height(300)])
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
                let nearby = await BusDatabase.shared.stops(near: center, radius: Self.candidateRadius)
                // 미리 고른 정류장이 반경 계산에서 빠지는 일이 없도록 합친다.
                candidates = (initialStop.map { [$0] } ?? []) + nearby.filter { $0.id != initialStop?.id }
                if let running = viewModel.runningStop {
                    // 이미 안내 중이면 다른 정류장을 열어도 안내 중인 정류장을 보여 준다.
                    candidates = [running] + candidates.filter { $0.id != running.id }
                    selectedStopID = running.id
                } else if selectedStopID == nil {
                    selectedStopID = candidates.first?.id
                }
                viewModel.select(selectedStop)
                if let stop = selectedStop {
                    camera = Self.camera(for: stop.coordinate, radius: alarmRadius)
                }
            }
            .onChange(of: selectedStopID) { _, _ in
                viewModel.select(selectedStop)
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

            if let stop = selectedStop {
                MapCircle(center: stop.coordinate, radius: alarmRadius)
                    .foregroundStyle(Color("mainpurple").opacity(0.12))
                    .stroke(Color("mainpurple").opacity(0.6), lineWidth: 1)
            }

            // 고른 정류장이 다른 핀에 가리지 않도록 맨 마지막에 그린다.
            ForEach(orderedCandidates) { stop in
                let isSelected = stop.id == selectedStopID
                Annotation(stop.name, coordinate: stop.coordinate, anchor: .center) {
                    StopPin(isSelected: isSelected)
                        .onTapGesture {
                            // 알람 중에는 목적지를 바꾸지 않는다.
                            guard !viewModel.isRunning else { return }
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
        .onChange(of: alarmRadius) { _, _ in
            // 알람 반경 원이 화면에 다 들어오도록 맞춘다.
            guard let stop = selectedStop else { return }
            withAnimation {
                camera = Self.camera(for: stop.coordinate, radius: alarmRadius)
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

                if viewModel.isRunning {
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

            Picker("알람 거리", selection: $alarmRadius) {
                ForEach(Self.radiusOptions, id: \.self) { option in
                    Text(StopAlarmViewModel.format(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 10)

            let canStart = !isAlreadyInside && !routeAlarm.isRunning
            Button {
                viewModel.start(stop: stop, radius: alarmRadius)
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

            Text("\(StopAlarmViewModel.format(alarmRadius)) 앞에서 알려드릴게요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Button(role: .destructive) {
                viewModel.stop()
            } label: {
                Text("안내 종료")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.top, 16)
        }
    }

    private var startTitle: String {
        if routeAlarm.isRunning { return "버스 안내가 진행 중이에요" }
        return isAlreadyInside ? "이미 알람 거리 안에 있어요" : "알람 시작"
    }

    private var isAlreadyInside: Bool {
        guard let distance = viewModel.distance else { return false }
        return distance <= alarmRadius
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

    var body: some View {
        Image(systemName: "bus.fill")
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
