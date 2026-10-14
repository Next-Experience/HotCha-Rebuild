import SwiftData
import SwiftUI

struct HomeScreen: View {
    /// 탭 바의 검색을 누를 때마다 값이 바뀐다. 바뀌면 위쪽 검색창을 연다.
    let searchRequest: Int
    /// 이용 기록의 「더보기」를 누르면 불린다. 이용 기록 탭으로 넘어간다.
    let onShowHistory: () -> Void
    @Query(sort: \Usage_history.get_off_timestamp, order: .reverse) private var busHistories: [Usage_history]
    @State private var stopHistories = StopAlarmHistory.load()
    @Query private var bookmarks: [Bookmarkmodel]
    @EnvironmentObject private var session: RouteAlarmSession
    @EnvironmentObject private var stopAlarm: StopAlarmViewModel
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var homeSearchQuery = ""
    @State private var isSearchPresented = false
    @State private var searchDestination: SearchDestination?
    /// 즐겨찾기를 추가하려고 연 검색. 값은 종류("집" · "회사" · "0")다.
    @State private var bookmarkSearch: BookmarkSearchRequest?

    var body: some View {
        NavigationStack {
            Group {
                if isSearchPresented || !homeSearchQuery.isEmpty {
                    // 검색창이 열리면 홈 내용 자리에 결과가 바로 나온다.
                    SearchView(
                        textfiledValue: $homeSearchQuery,
                        searchActivate: .constant(true),
                        destination: $searchDestination,
                        location: locationViewModel.location
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            HomeStatusBanner(status: bannerStatus, action: openBanner)

                            HistorySection(
                                entries: Array(recentEntries.prefix(3)),
                                hasMore: recentEntries.count > 3,
                                onSelect: { searchDestination = $0.destination },
                                onShowAll: onShowHistory
                            )

                            FavoriteSection(
                                bookmarks: bookmarks,
                                onAdd: { type in
                                    bookmarkSearch = BookmarkSearchRequest(type: type)
                                },
                                onSelect: { bookmark in
                                    searchDestination = .route(
                                        Bus_info_seoul(from: bookmark.bus),
                                        startingAt: bookmark.destination_stop_id
                                    )
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(HotChaContentBackground())
            .navigationTitle(currentRegion)
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $homeSearchQuery,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "버스 · 정류장 · 장소"
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: searchRequest) { _, _ in
                isSearchPresented = true
            }
            .navigationDestination(item: $searchDestination) { destination in
                switch destination {
                case .bus(let route):
                    RouteAlarmScreen(bus: route, mode: .alarm(startingAt: nil))
                case .route(let route, let stationId):
                    RouteAlarmScreen(bus: route, mode: .alarm(startingAt: stationId))
                case .stop(let stop):
                    StopAlarmView(stop: stop)
                case .place(let place):
                    StopAlarmView(placeName: place.name, coordinate: place.coordinate)
                }
            }
            .sheet(item: $bookmarkSearch) { request in
                BookmarkSearchSheet(bookmarkType: request.type)
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                stopHistories = StopAlarmHistory.load()
            }
            .onAppear {
                stopHistories = StopAlarmHistory.load()
                locationViewModel.requestPermission()
                locationViewModel.requestalwaysPermission()
                locationViewModel.requestLocation()
            }
        }
    }

    private var recentEntries: [HistoryEntry] {
        HistoryEntry.merged(buses: busHistories, stops: stopHistories)
    }

    // MARK: - 상태 배너

    /// 버스 안내 → 정류장 안내 → 없음 순으로 하나만 고른다.
    private var bannerStatus: HomeStatusBanner.Status {
        if session.isRunning, let bus = session.bus {
            let name = session.destinationStop?.stationNm ?? "도착 정류장"
            let detail: String
            switch session.remainingStops {
            case .none: detail = "\(bus.busRouteNm)번 버스 · \(name)"
            case .some(let n) where n > 0: detail = "\(bus.busRouteNm)번 버스 · \(name)까지 \(n)정류장 남음"
            case .some(0): detail = "\(bus.busRouteNm)번 버스 · \(name)에 도착했어요"
            case .some(let n): detail = "\(bus.busRouteNm)번 버스 · \(name)을 \(-n)정류장 지났어요"
            }
            return session.hasAlarmFired ? .arriving(detail: detail) : .travelling(detail: detail, image: BusArt.imageName(for: bus))
        }
        if let stop = stopAlarm.runningStop {
            let detail = stopAlarm.distance.map { "\(stop.name)까지 \(StopAlarmViewModel.format($0)) 남음" } ?? stop.name
            return stopAlarm.didFire ? .arriving(detail: detail) : .travelling(detail: detail, image: Clay.busStop.rawValue)
        }
        return .idle
    }

    /// 안내 중이면 그 안내 화면으로, 아니면 검색을 연다. 안내 종료는 안내 화면에서만 한다.
    private func openBanner() {
        if session.isRunning, let bus = session.bus {
            searchDestination = .bus(bus)
        } else if let stop = stopAlarm.runningStop {
            searchDestination = .stop(stop)
        } else {
            isSearchPresented = true
        }
    }

    private var currentRegion: String {
        locationViewModel.regionName ?? "현재 위치"
    }
}

private struct BookmarkSearchRequest: Identifiable {
    let type: String
    var id: String { type }
}

/// 최근 이용 기록 세 건. 더 보려면 이용 기록 탭으로 넘어간다.
private struct HistorySection: View {
    let entries: [HistoryEntry]
    let hasMore: Bool
    let onSelect: (HistoryEntry) -> Void
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이용 기록")
                .font(.title2.weight(.bold))

            if entries.isEmpty {
                HStack(spacing: 14) {
                    ClayIcon(clay: .bus)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("이용 기록이 없어요")
                            .font(.body.weight(.semibold))
                        Text("알림을 완료하면 여기서 바로 다시 시작할 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        Button { onSelect(entry) } label: {
                            HistoryRow(entry: entry)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if entry.id != entries.last?.id { Divider().padding(.leading, 62) }
                    }

                    if hasMore {
                        Divider().padding(.leading, 62)
                        Button(action: onShowAll) {
                            Label("더보기", systemImage: "chevron.right")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("mainpurple"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct FavoriteSection: View {
    let bookmarks: [Bookmarkmodel]
    let onAdd: (String) -> Void
    let onSelect: (Bookmarkmodel) -> Void
    @Environment(\.modelContext) private var modelContext

    private static let maxCount = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("즐겨찾기")
                .font(.title2.weight(.bold))

            VStack(spacing: 0) {
                favoriteRow(label: "집", type: 1)
                Divider().padding(.leading, 62)
                favoriteRow(label: "회사", type: 2)

                ForEach(bookmarks.filter { $0.bookmark_type == 0 }) { bookmark in
                    Divider().padding(.leading, 62)
                    Button { onSelect(bookmark) } label: {
                        favoriteLabel(
                            bookmark.bookmark_label,
                            detail: "\(bookmark.bus_no)번 · \(bookmark.destination_stop_name)",
                            clay: Clay.forBookmark(type: 0, label: bookmark.bookmark_label)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu { deleteButton(bookmark) }
                }

                if bookmarks.count < Self.maxCount {
                Divider().padding(.leading, 62)
                Button { onAdd("0") } label: {
                    Label("즐겨찾기 추가", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color("mainpurple"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15)
                }
                }
            }
        }
    }

    /// 길게 눌러 지운다.
    private func deleteButton(_ bookmark: Bookmarkmodel) -> some View {
        Button("즐겨찾기 삭제", systemImage: "trash", role: .destructive) {
            modelContext.delete(bookmark)
        }
    }

    @ViewBuilder
    private func favoriteRow(label: String, type: Int) -> some View {
        if let bookmark = bookmarks.first(where: { $0.bookmark_type == type }) {
            Button { onSelect(bookmark) } label: {
                favoriteLabel(
                    bookmark.bookmark_label,
                    detail: "\(bookmark.bus_no)번 · \(bookmark.destination_stop_name)",
                    clay: Clay.forBookmark(type: type, label: label)
                )
            }
            .buttonStyle(.plain)
            .contextMenu { deleteButton(bookmark) }
        } else {
            Button { onAdd(label) } label: {
                favoriteLabel(
                    "\(label) 알림 추가",
                    detail: "자주 가는 곳의 버스 알림을 등록하세요.",
                    clay: Clay.forBookmark(type: type, label: label)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func favoriteLabel(_ title: String, detail: String, clay: Clay) -> some View {
        HStack(spacing: 14) {
            ClayIcon(clay: clay)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
