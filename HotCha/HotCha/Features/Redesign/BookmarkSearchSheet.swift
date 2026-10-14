import SwiftData
import SwiftUI

/// 즐겨찾기에 넣을 버스나 정류장을 고르는 시트.
/// 버스를 고르면 노선 화면에서 내릴 정류장까지 정하고, 정류장을 고르면 지도에서 확인한 뒤 저장한다(어느 버스든 타면 되는 즐겨찾기).
struct BookmarkSearchSheet: View {
    /// "집" · "회사" · 그 밖의 값(직접 이름 붙임)
    let bookmarkType: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var destination: SearchDestination?
    @State private var isSearchPresented = true

    var body: some View {
        NavigationStack {
            SearchView(
                textfiledValue: $query,
                searchActivate: .constant(true),
                destination: $destination,
                isBookmark: true
            )
            .background(HotChaContentBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .searchable(
                text: $query,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "버스 번호 · 정류장"
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationDestination(item: $destination) { destination in
                switch destination {
                case .bus(let route):
                    RouteAlarmScreen(bus: route, mode: .saveBookmark(type: bookmarkType)) {
                        dismiss()
                    }
                case .stop(let stop):
                    // 같은 이름의 정류장이 길 양쪽에 있다. 지도에서 보고 고른 뒤 저장한다.
                    StopAlarmView(
                        stop: stop,
                        asksBookmarkName: !["집", "회사"].contains(bookmarkType),
                        onSaveBookmark: save
                    )
                default:
                    EmptyView()
                }
            }
        }
        .tint(Color("mainpurple"))
        .scrollIndicators(.hidden)
    }

    /// 지도에서 확인한 정류장을 저장한다. 집 · 회사는 그 이름으로, 나머지는 붙인 이름(비우면 정류장 이름)으로.
    private func save(_ stop: BusStopRecord, name: String) {
        let type: Int
        let label: String
        switch bookmarkType {
        case "집": (type, label) = (1, "집")
        case "회사": (type, label) = (2, "회사")
        default: (type, label) = (0, name.trimmingCharacters(in: .whitespaces))
        }
        modelContext.insert(Bookmarkmodel(stop: stop, label: label.isEmpty ? stop.name : label, type: type))
        dismiss()
    }

    private var title: String {
        switch bookmarkType {
        case "집", "회사": return "\(bookmarkType) 알림 추가"
        default: return "즐겨찾기 추가"
        }
    }
}
