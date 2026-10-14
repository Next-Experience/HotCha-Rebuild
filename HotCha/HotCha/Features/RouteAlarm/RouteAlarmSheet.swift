//
//  RouteAlarmSheet.swift
//  HotCha
//
//  노선 알람 화면의 시스템 시트. 정류장을 고르고, 안내 중에는 지금 상황을 보여 준다.
//

import SwiftData
import SwiftUI

struct RouteAlarmSheet: View {
    let bus: Bus_info_seoul
    let mode: RouteAlarmScreen.Mode
    @Binding var detent: PresentationDetent
    let onFinish: () -> Void
    let onBookmarkSaved: () -> Void

    @EnvironmentObject private var session: RouteAlarmSession
    @EnvironmentObject private var stopAlarm: StopAlarmViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmarkmodel]

    @AppStorage("alarmStopDistanceFromDestination") private var stopsBefore = 2
    @AppStorage("soundToggle") private var soundOn = true
    @AppStorage("vibrationToggle") private var vibrationOn = true

    @State private var query = ""
    @State private var bookmarkName = ""
    @State private var asksBookmarkName = false

    private static let maxBookmarks = 6

    var body: some View {
        NavigationStack {
            Group {
                if session.isLoading {
                    ProgressView("정류장을 불러오는 중이에요")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if session.loadFailed {
                    ContentUnavailableView {
                        Label("정류장을 불러오지 못했어요", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("네트워크 연결을 확인하고 다시 시도해 주세요.")
                    } actions: {
                        Button("다시 시도") { session.load(bus) }
                            .buttonStyle(.borderedProminent)
                    }
                } else if session.isRunning {
                    runningList
                } else {
                    choosingList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !session.isRunning && !session.isLoading && !session.loadFailed {
                    ToolbarItem(placement: .confirmationAction) {
                        primaryButton
                    }
                }
            }
        }
        .tint(Color("mainpurple"))
        .scrollIndicators(.hidden)
        .alert("즐겨찾기 이름", isPresented: $asksBookmarkName) {
            TextField(session.destinationStop?.stationNm ?? "이름", text: $bookmarkName)
            Button("저장") { saveBookmark(type: 0, label: bookmarkName) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(bus.busRouteNm)번 · \(session.destinationStop?.stationNm ?? "")")
        }
    }

    private var title: String {
        if session.isRunning { return "\(bus.busRouteNm)번 안내 중" }
        return "\(bus.busRouteNm)번 · 내릴 정류장"
    }

    // MARK: 정류장 고르기

    private var choosingList: some View {
        ScrollViewReader { proxy in
            List {
                if session.destinationStop != nil {
                    Section("알림") {
                        Stepper(value: $stopsBefore, in: 1...5) {
                            LabeledContent("알림 시점", value: "\(stopsBefore)정류장 전")
                        }
                        if let stop = session.alarmStop {
                            LabeledContent("알림 정류장", value: stop.stationNm)
                        }
                        Toggle("소리", isOn: $soundOn)
                        Toggle("진동", isOn: $vibrationOn)
                    }
                    .id(Self.alarmSectionID)
                }

                Section {
                    ForEach(filteredStops, id: \.offset) { index, stop in
                        stopRow(index: index, stop: stop)
                    }
                } header: {
                    Text("\(bus.stStationNm) → \(bus.edStationNm)")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $query, prompt: "정류장 이름 검색")
            .onChange(of: session.destinationIndex) { _, _ in
                // 정류장을 고르면 맨 위의 알림 설정이 보이게 올린다.
                withAnimation { proxy.scrollTo(Self.alarmSectionID, anchor: .top) }
            }
        }
    }

    private static let alarmSectionID = "alarm-section"

    private var filteredStops: [(offset: Int, element: BusStop)] {
        let all = Array(session.stops.enumerated())
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return all }
        return all.filter { $0.element.stationNm.localizedCaseInsensitiveContains(text) }
    }

    private func stopRow(index: Int, stop: BusStop) -> some View {
        let isDestination = index == session.destinationIndex
        let selectable = RouteAlarmSession.isSelectable(stop)
        return Button {
            session.destinationIndex = index
            query = ""
            detent = .medium
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isDestination ? "flag.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDestination ? Color("mainpurple") : Color.secondary.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.stationNm)
                        .font(.body.weight(isDestination ? .semibold : .regular))
                        .foregroundStyle(selectable ? .primary : .tertiary)
                    if stop.stationNo > 0 {
                        Text(String(format: "%05d", stop.stationNo))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if !selectable {
                    Text("미정차")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }

    /// 시트 오른쪽 위의 확인 버튼. 정류장을 고르기 전에는 꺼져 있다.
    @ViewBuilder
    private var primaryButton: some View {
        let ready = session.destinationStop != nil
        switch mode {
        case .alarm:
            Button("알림 시작") {
                // 안내는 한 번에 하나다. 정류장 알람이 돌고 있으면 끝내고 시작한다.
                stopAlarm.stop()
                if session.start() { detent = .medium }
            }
            .fontWeight(.semibold)
            .disabled(!ready)
        case .saveBookmark(let type):
            Button("저장") {
                switch type {
                case "집": saveBookmark(type: 1, label: "집")
                case "회사": saveBookmark(type: 2, label: "회사")
                default:
                    bookmarkName = ""
                    asksBookmarkName = true
                }
            }
            .fontWeight(.semibold)
            .disabled(!ready)
        }
    }

    // MARK: 안내 중

    private var runningList: some View {
        // 안내 종료는 목록 아래 시트 안쪽 맨 끝에 고정한다. 목록은 그 위에서 끝나서 버튼 뒤로 비치지 않는다.
        // 시트를 가장 낮게 내렸을 때는 숨긴다.
        VStack(spacing: 0) {
            runningRows
            if detent != RouteAlarmScreen.peekDetent {
                FinishGuidanceButton(action: finish)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
        }
    }

    private var runningRows: some View {
        List {
            Section {
                statusHeader
                    .listRowSeparator(.hidden)
                if let progress {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: progress)
                            .tint(Color("mainpurple"))
                            .animation(.smooth, value: progress)
                        HStack {
                            Text(boardedStop?.stationNm ?? "")
                            Spacer()
                            Text(session.destinationStop?.stationNm ?? "")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                ForEach(upcoming, id: \.offset) { index, stop in
                    RouteTimelineRow(
                        name: stop.stationNm,
                        kind: timelineKind(at: index),
                        isFirst: index == upcoming.first?.offset,
                        isLast: index == upcoming.last?.offset
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            } header: {
                Text("남은 정류장")
            } footer: {
                if session.currentStop == nil {
                    Text("위치를 받으면 지금 정류장부터 보여 드려요.")
                }
            }

            Section {
                Toggle("소리", isOn: $soundOn)
                Toggle("진동", isOn: $vibrationOn)
            }

            Section {
                Button {
                    bookmarkName = ""
                    asksBookmarkName = true
                } label: {
                    Label("즐겨찾기에 추가", systemImage: "star")
                }
                .disabled(bookmarks.count >= Self.maxBookmarks)
            } footer: {
                if bookmarks.count >= Self.maxBookmarks {
                    Text("즐겨찾기는 \(Self.maxBookmarks)개까지 저장할 수 있어요.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
    }

    /// 버스 그림 · 남은 정류장 수 · 내릴 정류장. 시트를 가장 낮게 내려도 이것만은 보인다.
    private var statusHeader: some View {
        HStack(spacing: 14) {
            ClayIcon(imageName: BusArt.imageName(for: bus), size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(headerCaption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(remainingText)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color("mainpurple"))
                    .contentTransition(.numericText())
                    .animation(.smooth, value: session.remainingStops)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var headerCaption: String {
        let name = session.destinationStop?.stationNm ?? "도착 정류장"
        return "\(bus.busRouteNm)번 · \(name)까지"
    }

    /// 홈 배너 · 잠금 화면과 같은 문구다.
    private var remainingText: String {
        HotChaGuidance(
            kind: .route,
            busNumber: bus.busRouteNm,
            destination: session.destinationStop?.stationNm ?? "도착 정류장",
            remainingStops: session.remainingStops,
            remainingMeters: nil,
            hasAlarmFired: session.hasAlarmFired
        ).headline
    }

    private var boardedStop: BusStop? {
        session.boardedIndex.flatMap { session.stops.indices.contains($0) ? session.stops[$0] : nil }
    }

    /// 탄 정류장에서 내릴 정류장까지 얼마나 왔나. 첫 위치를 받기 전에는 nil 이다.
    private var progress: Double? {
        guard let start = session.boardedIndex, let current = session.currentIndex,
            let destination = session.destinationIndex, destination > start
        else { return nil }
        return min(max(Double(current - start) / Double(destination - start), 0), 1)
    }

    /// 지금 정류장부터 내릴 정류장까지. 위치를 모르면 내릴 정류장 앞 몇 개만 보여 준다.
    private var upcoming: [(offset: Int, element: BusStop)] {
        guard let destination = session.destinationIndex, session.stops.indices.contains(destination) else {
            return []
        }
        let from = session.currentIndex ?? max(destination - stopsBefore - 2, 0)
        guard from <= destination else { return [(destination, session.stops[destination])] }
        return Array(session.stops.enumerated())[from...destination].map { ($0.offset, $0.element) }
    }

    private func timelineKind(at index: Int) -> RouteTimelineRow.Kind {
        if index == session.destinationIndex { return .destination }
        if index == session.currentIndex { return .current }
        if let alarm = session.alarmStop, session.stops[index].station == alarm.station,
            session.stops[index].seq == alarm.seq
        {
            return .alarm
        }
        return .normal
    }

    // MARK: 동작

    private func finish() {
        session.finish(in: modelContext)
        onFinish()
    }

    private func saveBookmark(type: Int, label: String) {
        guard let destination = session.destinationStop else { return }
        let name = label.trimmingCharacters(in: .whitespaces)
        modelContext.insert(
            Bookmarkmodel(
                bus: BusFavoriteHistory(from: bus),
                route_id: bus.busRouteId,
                city_code: bus.city_code,
                destination_stop_id: destination.station,
                destination_stop_name: destination.stationNm,
                bus_no: bus.busRouteNm,
                route_type: bus.routeType,
                bookmark_label: name.isEmpty ? destination.stationNm : name,
                bookmark_type: type
            ))
        if case .saveBookmark = mode {
            onBookmarkSaved()
        }
    }
}

// MARK: - 남은 정류장 노선도

/// 시트의 세로 노선도 한 줄. 줄끼리 선이 이어지도록 위아래 여백 없이 쌓는다.
private struct RouteTimelineRow: View {
    enum Kind {
        case current
        case alarm
        case destination
        case normal
    }

    let name: String
    let kind: Kind
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                VStack(spacing: 0) {
                    Rectangle().fill(isFirst ? .clear : Color("mainpurple").opacity(0.35))
                    Rectangle().fill(isLast ? .clear : Color("mainpurple").opacity(0.35))
                }
                .frame(width: 4)
                marker
            }
            .frame(width: 30)

            Text(name)
                .font(kind == .normal ? .body : .body.weight(.semibold))
                .foregroundStyle(kind == .normal ? .secondary : .primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            if let tag {
                Text(tag)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("mainpurple"))
            }
        }
        .frame(height: 48)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var marker: some View {
        switch kind {
        case .current:
            symbolMarker("bus.fill", filled: true)
        case .alarm:
            symbolMarker("bell.fill", filled: false)
        case .destination:
            symbolMarker("flag.fill", filled: true)
        case .normal:
            Circle()
                .fill(.white)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(Color("mainpurple").opacity(0.6), lineWidth: 2.5))
        }
    }

    private func symbolMarker(_ systemImage: String, filled: Bool) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(filled ? Color.white : Color("mainpurple"))
            .frame(width: 26, height: 26)
            .background(Circle().fill(filled ? Color("mainpurple") : Color.white))
            .overlay(Circle().stroke(Color("mainpurple"), lineWidth: filled ? 0 : 2))
    }

    private var tag: String? {
        switch kind {
        case .current: return "지금"
        case .alarm: return "알림"
        case .destination: return "하차"
        case .normal: return nil
        }
    }
}

/// 안내 종료. iOS 26 부터는 시스템 글라스 버튼, 그 전에는 같은 캡슐 모양의 기본 버튼이다.
/// 노선 시트와 정류장 시트가 함께 쓴다.
struct FinishGuidanceButton: View {
    let action: () -> Void

    var body: some View {
        let button = Button(role: .destructive, action: action) {
            Text("안내 종료")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .tint(.red)

        if #available(iOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
        }
    }
}
