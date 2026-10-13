//
//  StopAlarmView.swift
//  HotCha
//
//  정류장(또는 장소 주변 정류장)을 지도에서 고르고 거리 기준 알람을 맞추는 화면.
//

import SwiftUI
import MapKit

struct StopAlarmView: View {
    /// 지도를 처음 맞출 중심. 정류장 검색이면 그 정류장, 장소 검색이면 그 장소다.
    let title: String
    let center: CLLocationCoordinate2D
    /// 정류장 검색으로 들어왔을 때 미리 골라 둘 정류장
    let initialStop: BusStopRecord?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StopAlarmViewModel()
    @AppStorage("stopAlarmRadius") private var alarmRadius: Double = 500

    @State private var candidates: [BusStopRecord] = []
    @State private var selectedStopID: String?
    @State private var camera: MapCameraPosition

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

    private static func camera(for coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 0) -> MapCameraPosition {
        let span = max(700, radius * 2.6)
        return .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: span, longitudinalMeters: span))
    }

    private var selectedStop: BusStopRecord? {
        candidates.first { $0.id == selectedStopID }
    }

    var body: some View {
        VStack(spacing: 0) {
            map
            bottomCard
        }
        .background(Color("gray50"))
        .overlay {
            if viewModel.didFire, let stop = selectedStop {
                arrivalOverlay(stop: stop)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.didFire)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 알람 중에는 화면을 떠나면 알람이 끊기므로 뒤로가기를 숨긴다.
            if !viewModel.isRunning {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .toolbarBackground(.gray900, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let nearby = await BusDatabase.shared.stops(near: center, radius: Self.candidateRadius)
            // 미리 고른 정류장이 반경 계산에서 빠지는 일이 없도록 합친다.
            candidates = (initialStop.map { [$0] } ?? []) + nearby.filter { $0.id != initialStop?.id }
            if selectedStopID == nil {
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
            viewModel.stop()
        }
    }

    // MARK: - 지도

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()

            if initialStop == nil {
                Marker(title, systemImage: "mappin", coordinate: center)
                    .tint(Color("gray600"))
            }

            if let stop = selectedStop {
                MapCircle(center: stop.coordinate, radius: alarmRadius)
                    .foregroundStyle(Color("mainpurple").opacity(0.12))
                    .stroke(Color("mainpurple").opacity(0.6), lineWidth: 1)
            }

            // 고른 정류장이 다른 핀에 가리지 않도록 맨 마지막에 그린다.
            ForEach(candidates.filter { $0.id != selectedStopID } + (selectedStop.map { [$0] } ?? [])) { stop in
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
                    .font(.pretendard(.bold, size: 22))
                    .foregroundStyle(Color("gray900"))
                    .lineLimit(2)

                Text(subtitle(for: stop))
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color("gray400"))
                    .padding(.top, 6)

                if viewModel.isRunning {
                    runningSection
                } else {
                    setupSection(stop: stop)
                }
            } else {
                Text("주변에 정류장이 없어요")
                    .font(.pretendard(.bold, size: 20))
                    .foregroundStyle(Color("gray900"))
                Text("다른 장소나 정류장 이름으로 다시 검색해 보세요.")
                    .font(.pretendard(.medium, size: 14))
                    .foregroundStyle(Color("gray400"))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 24, leading: 20, bottom: 28, trailing: 20))
        .background(Color("gray50"))
    }

    private func setupSection(stop: BusStopRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("얼마나 앞에서 알려드릴까요?")
                .font(.pretendard(.medium, size: 16))
                .foregroundStyle(Color("gray600"))
                .padding(.top, 20)

            HStack(spacing: 8) {
                ForEach(Self.radiusOptions, id: \.self) { option in
                    let isSelected = option == alarmRadius
                    Text(StopAlarmViewModel.format(option))
                        .font(.pretendard(.semibold, size: 16))
                        .foregroundStyle(isSelected ? Color("gray50") : Color("gray600"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color("mainpurple") : Color("gray150")))
                        .contentShape(Rectangle())
                        .onTapGesture { alarmRadius = option }
                }
            }
            .padding(.top, 10)

            let canStart = !isAlreadyInside
            Button(action: { viewModel.start(stop: stop, radius: alarmRadius) }) {
                Text(canStart ? "알람 시작" : "이미 알람 거리 안에 있어요")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(canStart ? Color("gray50") : Color("gray150"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 8).fill(canStart ? Color("mainpurple") : Color("gray200")))
            }
            .disabled(!canStart)
            .padding(.top, 16)
        }
    }

    private var runningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(viewModel.distance.map(StopAlarmViewModel.format) ?? "위치 확인 중")
                    .font(.pretendard(.bold, size: 28))
                    .foregroundStyle(Color("mainpurple"))
                if viewModel.distance != nil {
                    Text("남았어요")
                        .font(.pretendard(.semibold, size: 18))
                        .foregroundStyle(Color("gray700"))
                }
            }
            .padding(.top, 20)

            Text("\(StopAlarmViewModel.format(alarmRadius)) 앞에서 알려드릴게요.")
                .font(.pretendard(.medium, size: 14))
                .foregroundStyle(Color("gray400"))
                .padding(.top, 6)

            Button(action: { viewModel.stop() }) {
                Text("안내 종료")
                    .font(.pretendard(.semibold, size: 20))
                    .foregroundStyle(Color("gray700"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("gray150")))
            }
            .padding(.top, 16)
        }
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

    // MARK: - 알람이 울렸을 때

    private func arrivalOverlay(stop: BusStopRecord) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("곧 도착해요")
                    .font(.pretendard(.semibold, size: 16))
                    .foregroundStyle(Color("gray300"))
                    .padding(.bottom, 12)

                Text(stop.name)
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(Color("gray50"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)

                Text("안내 종료")
                    .font(.pretendard(.semibold, size: 18))
                    .padding(13)
                    .foregroundStyle(Color("gray900"))
                    .frame(width: 150)
                    .background(Capsule().fill(Color("mainpurple")))
                    .onTapGesture { viewModel.stop() }
            }
            .frame(width: 320, height: 320)
            .background(Circle().fill(Color("mainpurple").opacity(0.3)))
        }
    }
}

/// 지도 위 정류장 핀
private struct StopPin: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "bus.fill")
            .font(.system(size: isSelected ? 18 : 11, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color("gray500"))
            .frame(width: isSelected ? 42 : 26, height: isSelected ? 42 : 26)
            .background(Circle().fill(isSelected ? Color("mainpurple") : Color.white))
            .overlay(Circle().stroke(isSelected ? Color.white : Color("gray300"), lineWidth: isSelected ? 3 : 1))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            // 작은 핀도 누르기 쉽게 터치 영역을 넓힌다.
            .padding(6)
            .contentShape(Circle())
    }
}

#Preview {
    NavigationStack {
        StopAlarmView(stop: BusStopRecord(
            id: "preview", name: "강남역", latitude: 37.4979, longitude: 127.0276,
            arsNumber: "22009", cityName: "서울"
        ))
    }
}
