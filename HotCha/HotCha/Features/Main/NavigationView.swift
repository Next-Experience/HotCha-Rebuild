//
//  SegmentedNavigation.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftData
import SwiftUI

struct NavigationView: View {
    @State private var selectedTab = 0
    /// 탭 바의 검색을 누른 횟수. 검색은 화면이 아니라 홈 위쪽 검색창을 여는 버튼이다.
    @State private var searchRequest = 0
    /// 노선 알람은 화면을 벗어나도 이어져야 해서 탭 전체가 하나를 나눠 쓴다.
    @StateObject private var routeAlarmSession = RouteAlarmSession()
    @StateObject private var stopAlarmSession = StopAlarmViewModel()
    @Environment(\.modelContext) private var modelContext
    /// 알람 화면을 띄우고 있는가. 안내 화면의 시트가 내려간 뒤에 띄우려고 상태를 따로 둔다.
    @State private var showsRinging = false
    /// 개발자 메뉴에서 미리 보기로 띄웠는가
    @State private var isPreviewingAlarm = false
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassTabView
            } else {
                fallbackTabView
            }
        }
        .tint(Color("mainpurple"))
        // 스크롤 막대는 앱 전체에서 숨긴다.
        .scrollIndicators(.hidden)
        .environmentObject(routeAlarmSession)
        .environmentObject(stopAlarmSession)
        .fullScreenCover(isPresented: $showsRinging) {
            AlarmRingingView(
                content: ringingContent,
                onConfirm: confirmAlarm,
                onFinish: finishGuidance
            )
        }
        .onChange(of: isRinging) { _, ringing in
            guard ringing else {
                showsRinging = false
                return
            }
            // 안내 화면의 시트가 내려갈 틈을 준다. 시트가 떠 있으면 전체 화면을 띄울 수 없다.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showsRinging = isRinging
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .previewAlarmRinging)) { _ in
            isPreviewingAlarm = true
            startAlarmToggle(
                isOn: true,
                title: "핫챠! 내릴 준비를 해주세요",
                body: "알람 미리 보기예요",
                useSound: UserDefaults.standard.object(forKey: "soundToggle") as? Bool ?? true,
                useVibration: UserDefaults.standard.object(forKey: "vibrationToggle") as? Bool ?? true
            )
        }
    }

    // MARK: - 알람 화면

    private var isRinging: Bool {
        routeAlarmSession.alarmIsRinging || stopAlarmSession.isRinging || isPreviewingAlarm
    }

    private var ringingContent: AlarmRingingContent {
        if routeAlarmSession.alarmIsRinging, let bus = routeAlarmSession.bus {
            let remaining = routeAlarmSession.remainingStops.map { $0 > 0 ? "\($0)정류장 남음" : "곧 도착" } ?? "곧 도착"
            return AlarmRingingContent(
                destination: routeAlarmSession.destinationStop?.stationNm ?? "",
                detail: "\(bus.busRouteNm)번 버스 · \(remaining)"
            )
        }
        if stopAlarmSession.isRinging, let stop = stopAlarmSession.runningStop {
            let remaining = stopAlarmSession.distance.map { "\(StopAlarmViewModel.format($0)) 남음" } ?? "곧 도착"
            return AlarmRingingContent(destination: stop.name, detail: "정류장 알림 · \(remaining)")
        }
        return .preview
    }

    /// 소리만 끄고 안내는 이어 간다.
    private func confirmAlarm() {
        if isPreviewingAlarm {
            startAlarmToggle(isOn: false, title: "", body: "", useSound: false, useVibration: false)
            isPreviewingAlarm = false
        }
        if routeAlarmSession.alarmIsRinging { routeAlarmSession.silence() }
        if stopAlarmSession.isRinging { stopAlarmSession.silence() }
    }

    private func finishGuidance() {
        if isPreviewingAlarm {
            confirmAlarm()
            return
        }
        if routeAlarmSession.isRunning { routeAlarmSession.finish(in: modelContext) }
        if stopAlarmSession.isRunning { stopAlarmSession.stop() }
        NotificationCenter.default.post(name: .alarmGuidanceFinished, object: nil)
    }

    @available(iOS 26.0, *)
    private var liquidGlassTabView: some View {
        TabView(selection: tabSelection) {
            Tab("홈", systemImage: "house", value: 0) {
                HomeScreen(searchRequest: searchRequest) { selectedTab = Self.historyTab }
            }
            Tab("이용 기록", systemImage: "clock", value: 1) {
                UsageHistoryScreen()
            }
            Tab("나의 핫챠", systemImage: "person.crop.circle", value: Self.myTab) {
                MyHotChaScreen()
            }
            Tab("검색", systemImage: "magnifyingglass", value: Self.searchTab) {
                Color.clear
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    /// 검색 탭은 고르는 대신 홈으로 돌아가 검색창을 연다.
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == Self.searchTab {
                    selectedTab = 0
                    searchRequest += 1
                } else {
                    selectedTab = newValue
                }
            }
        )
    }

    private static let historyTab = 1
    private static let myTab = 2
    private static let searchTab = 3

    private var fallbackTabView: some View {
        TabView(selection: tabSelection) {
            HomeScreen(searchRequest: searchRequest) { selectedTab = Self.historyTab }
                .tabItem { Label("홈", systemImage: "house") }
                .tag(0)
            UsageHistoryScreen()
                .tabItem { Label("이용 기록", systemImage: "clock") }
                .tag(1)
            MyHotChaScreen()
                .tabItem { Label("나의 핫챠", systemImage: "person.crop.circle") }
                .tag(Self.myTab)
            Color.clear
                .tabItem { Label("검색", systemImage: "magnifyingglass") }
                .tag(Self.searchTab)
        }
    }
}

struct HotChaContentBackground: View {
    var body: some View {
        // 위쪽에만 옅은 강조색 빛 두 개를 깔고 아래로 갈수록 사라지게 한다. 본문 카드는 바탕 위에 그대로 놓인다.
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground)
            ZStack {
                Color("mainpurple").opacity(0.06)
                RadialGradient(
                    colors: [Color("mainpurple").opacity(0.16), .clear],
                    center: UnitPoint(x: 0.08, y: 0.03), startRadius: 0, endRadius: 310)
                RadialGradient(
                    colors: [Color("mainpurple").opacity(0.13), .clear],
                    center: UnitPoint(x: 0.92, y: 0.12), startRadius: 0, endRadius: 270)
            }
            .frame(height: 360)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black.opacity(0.8), location: 0.28),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// 아직 프로젝트에 남아 있는 이전 홈 화면과의 컴파일 호환용 이름이다.
// 현재 탭 바 검색은 GlobalSearchScreen으로 직접 전환한다.
extension Notification.Name {
    static let openGlobalSearch = Notification.Name("OpenGlobalSearch")
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
