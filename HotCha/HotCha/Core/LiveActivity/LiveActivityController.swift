//
//  LiveActivityController.swift
//  HotCha
//
//  잠금 화면과 다이내믹 아일랜드에 뜨는 안내 하나를 시작·갱신·종료한다.
//  안내는 한 번에 하나라서 활동도 하나만 둔다.
//

import ActivityKit
import Foundation

final class LiveActivityController {
    static let shared = LiveActivityController()
    private init() {}

    private var activity: Activity<HotChaActivityAttributes>?
    private var lastState: HotChaActivityAttributes.ContentState?

    /// 안내를 시작한다. 남아 있던 활동이 있으면 먼저 치운다.
    func start(attributes: HotChaActivityAttributes, state: HotChaActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endAll()
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
            lastState = state
        } catch {
            // Live Activity 를 못 띄워도 알람 자체는 그대로 울린다.
            activity = nil
        }
    }

    /// 남은 정류장·거리를 갱신한다. 값이 그대로면 아무것도 하지 않는다.
    /// 알람 소리는 AlarmKit 시스템 알람이 낸다(결정 0005). 여기서는 경고음 없이 화면만 바꾼다.
    func update(_ state: HotChaActivityAttributes.ContentState) {
        guard let activity, state != lastState else { return }
        lastState = state
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    func end() {
        endAll()
    }

    /// 이 앱이 띄운 활동을 모두 끝낸다. 앱이 안내 중에 꺼졌다 켜지면 주인 없는 활동이 남아 있을 수 있다.
    func endAll() {
        activity = nil
        lastState = nil
        let running = Activity<HotChaActivityAttributes>.activities
        guard !running.isEmpty else { return }
        Task {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
