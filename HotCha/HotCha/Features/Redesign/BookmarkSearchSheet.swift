import SwiftData
import SwiftUI

/// 즐겨찾기에 넣을 버스나 정류장을 고르는 시트.
/// 버스를 고르면 노선 화면에서 내릴 정류장까지 정하고, 정류장을 고르면 바로 저장한다(어느 버스든 타면 되는 즐겨찾기).
struct BookmarkSearchSheet: View {
    /// "집" · "회사" · 그 밖의 값(직접 이름 붙임)
    let bookmarkType: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var destination: SearchDestination?
    @State private var isSearchPresented = true
    /// 이름을 물어보는 중인 정류장
    @State private var namingStop: BusStopRecord?
    @State private var bookmarkName = ""

    var body: some View {
        NavigationStack {
            SearchView(
                textfiledValue: $query,
                searchActivate: .constant(true),
                destination: choice,
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
                if case .bus(let route) = destination {
                    RouteAlarmScreen(bus: route, mode: .saveBookmark(type: bookmarkType)) {
                        dismiss()
                    }
                }
            }
            .alert(
                "즐겨찾기 이름",
                isPresented: Binding(get: { namingStop != nil }, set: { if !$0 { namingStop = nil } })
            ) {
                TextField(namingStop?.name ?? "이름", text: $bookmarkName)
                Button("저장") {
                    if let stop = namingStop { save(stop, type: 0, label: bookmarkName) }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("정류장 · \(namingStop?.name ?? "")")
            }
        }
        .tint(Color("mainpurple"))
        .scrollIndicators(.hidden)
    }

    /// 검색 결과를 고른 것. 버스는 노선 화면으로 넘어가고, 정류장은 여기서 저장한다.
    private var choice: Binding<SearchDestination?> {
        Binding(
            get: { destination },
            set: { picked in
                if case .stop(let stop) = picked {
                    pick(stop)
                } else {
                    destination = picked
                }
            }
        )
    }

    private func pick(_ stop: BusStopRecord) {
        switch bookmarkType {
        case "집": save(stop, type: 1, label: "집")
        case "회사": save(stop, type: 2, label: "회사")
        default:
            bookmarkName = ""
            namingStop = stop
        }
    }

    private func save(_ stop: BusStopRecord, type: Int, label: String) {
        let name = label.trimmingCharacters(in: .whitespaces)
        modelContext.insert(Bookmarkmodel(stop: stop, label: name.isEmpty ? stop.name : name, type: type))
        dismiss()
    }

    private var title: String {
        switch bookmarkType {
        case "집", "회사": return "\(bookmarkType) 알림 추가"
        default: return "즐겨찾기 추가"
        }
    }
}
