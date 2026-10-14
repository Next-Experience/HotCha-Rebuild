import SwiftUI

/// 즐겨찾기에 넣을 버스를 고르는 시트. 버스를 고르면 노선 화면에서 내릴 정류장까지 정한다.
struct BookmarkSearchSheet: View {
    /// "집" · "회사" · 그 밖의 값(직접 이름 붙임)
    let bookmarkType: String

    @Environment(\.dismiss) private var dismiss
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
                prompt: "버스 번호 검색"
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
        }
        .tint(Color("mainpurple"))
        .scrollIndicators(.hidden)
    }

    private var title: String {
        switch bookmarkType {
        case "집", "회사": return "\(bookmarkType) 알림 추가"
        default: return "즐겨찾기 추가"
        }
    }
}
