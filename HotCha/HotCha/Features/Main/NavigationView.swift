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
            AlarmRinger.shared.ring(title: "알람 미리 보기예요")
        }
        // 미리 보기 알람을 시스템 화면에서 끄면 앱의 알람 화면도 닫는다.
        .onReceive(NotificationCenter.default.publisher(for: .systemAlarmStopped)) { _ in
            isPreviewingAlarm = false
        }
    }

    // MARK: - 알람 화면

    private var isRinging: Bool {
        routeAlarmSession.alarmIsRinging || stopAlarmSession.isRinging || isPreviewingAlarm
    }

    private var ringingContent: AlarmRingingContent {
        // 문구는 홈 배너 · 잠금 화면과 같은 HotChaGuidance 에서 온다. "152번 · 2정류장 남았어요"
        if routeAlarmSession.alarmIsRinging, let bus = routeAlarmSession.bus {
            let destination = routeAlarmSession.destinationStop?.stationNm ?? ""
            let guidance = HotChaGuidance(
                kind: .route, busNumber: bus.busRouteNm, destination: destination,
                remainingStops: routeAlarmSession.remainingStops, remainingMeters: nil, hasAlarmFired: true)
            return AlarmRingingContent(destination: destination, detail: "\(guidance.label) · \(guidance.headline)")
        }
        if stopAlarmSession.isRinging, let stop = stopAlarmSession.runningStop {
            let guidance = HotChaGuidance(
                kind: .stop, busNumber: "", destination: stop.name, remainingStops: nil,
                remainingMeters: stopAlarmSession.distance.map { Int($0) }, hasAlarmFired: true)
            return AlarmRingingContent(destination: stop.name, detail: "\(guidance.label) · \(guidance.headline)")
        }
        return .preview
    }

    /// 알람만 끄고 안내는 이어 간다.
    private func confirmAlarm() {
        if isPreviewingAlarm {
            AlarmRinger.shared.stop()
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
        TabView(selection: $selectedTab) {
            Tab("홈", systemImage: "house", value: 0) {
                HomeScreen(searchRequest: 0) { selectedTab = Self.historyTab }
            }
            Tab("이용 기록", systemImage: "clock", value: 1) {
                UsageHistoryScreen()
            }
            Tab("지도", systemImage: "map", value: Self.mapTab) {
                StopMapScreen()
            }
            Tab("나의 핫챠", systemImage: "person.crop.circle", value: Self.myTab) {
                MyHotChaScreen()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    private static let historyTab = 1
    private static let mapTab = 2
    private static let myTab = 3

    private var fallbackTabView: some View {
        TabView(selection: $selectedTab) {
            HomeScreen(searchRequest: 0) { selectedTab = Self.historyTab }
                .tabItem { Label("홈", systemImage: "house") }
                .tag(0)
            UsageHistoryScreen()
                .tabItem { Label("이용 기록", systemImage: "clock") }
                .tag(1)
            StopMapScreen()
                .tabItem { Label("지도", systemImage: "map") }
                .tag(Self.mapTab)
            MyHotChaScreen()
                .tabItem { Label("나의 핫챠", systemImage: "person.crop.circle") }
                .tag(Self.myTab)
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
extension Notification.Name {
    static let openGlobalSearch = Notification.Name("OpenGlobalSearch")
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
