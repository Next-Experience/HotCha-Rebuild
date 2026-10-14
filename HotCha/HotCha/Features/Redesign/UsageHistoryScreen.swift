import SwiftData
import SwiftUI

struct UsageHistoryScreen: View {
    @Query(sort: \Usage_history.get_off_timestamp, order: .reverse) private var busHistories: [Usage_history]
    @Environment(\.modelContext) private var modelContext
    @State private var stopHistories = StopAlarmHistory.load()
    @State private var filter: HistoryEntry.Kind?
    @State private var restart: SearchDestination?

    private var entries: [HistoryEntry] {
        HistoryEntry.merged(buses: busHistories, stops: stopHistories)
            .filter { filter == nil || $0.kind == filter }
    }

    private var isEmpty: Bool { busHistories.isEmpty && stopHistories.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    // 목록 안에 두면 위로 쏠린다. 화면 한가운데에 둔다.
                    VStack(spacing: 12) {
                        Image(Clay.bus.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                        Text("이용 기록이 없어요")
                            .font(.title3.weight(.bold))
                        Text("알림을 완료하면 이곳에서 다시 확인할 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            Picker("종류", selection: $filter) {
                                Text("전체").tag(HistoryEntry.Kind?.none)
                                ForEach(HistoryEntry.Kind.allCases) { kind in
                                    Text(kind.rawValue).tag(HistoryEntry.Kind?.some(kind))
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }

                        Section {
                            ForEach(entries) { entry in
                                Button {
                                    restart = entry.destination
                                } label: {
                                    HistoryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button("삭제", systemImage: "trash", role: .destructive) { delete(entry) }
                                }
                            }
                        } footer: {
                            Text("누르면 같은 곳으로 다시 안내를 시작해요.")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(HotChaContentBackground())
            .navigationTitle("이용 기록")
            .navigationDestination(item: $restart) { destination in
                switch destination {
                case .route(let bus, let stationId):
                    RouteAlarmScreen(bus: bus, mode: .alarm(startingAt: stationId))
                case .stop(let stop):
                    StopAlarmView(stop: stop)
                case .bus, .place:
                    EmptyView()
                }
            }
            .onAppear { stopHistories = StopAlarmHistory.load() }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                stopHistories = StopAlarmHistory.load()
            }
        }
    }

    private func delete(_ entry: HistoryEntry) {
        switch entry {
        case .bus(let history):
            modelContext.delete(history)
        case .stop(let record):
            StopAlarmHistory.remove(record.id)
            stopHistories = StopAlarmHistory.load()
        }
    }
}
